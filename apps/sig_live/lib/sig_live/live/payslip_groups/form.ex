defmodule SigLive.PayslipGroups.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Organizations

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    ErrorTag,
    Field,
    Label,
    Select,
    Submit
  }

  alias Sig.HR.Payslips.PayslipGroupType

  alias SigLive.PayslipGroups.VerifiedRegistrations
  alias SigLive.Components.{Modal, Switch}

  @form_states [:open, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true

  data message, :string, default: nil
  data verified_registrations, :list, default: nil
  data payments_type, :atom, default: :standard, values: [:standard, :none]

  @impl true
  def update(assigns, socket) do
    selected_date = Sig.Date.next_month_start()

    socket =
      socket
      |> assign(assigns)
      |> assign_payables_due_dates(selected_date)
      |> assign(
        changeset: HR.batch_create_payslips_change(%{start_date: selected_date, type: :regular}),
        dates_for_select: build_dates_for_select(selected_date),
        sectors: Organizations.list_org_sectors(assigns.org),
        selected_date: selected_date,
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("handle_payments_type", _params, socket) do
    if socket.assigns.payments_type == :none do
      {:noreply, assign(socket, payments_type: :standard)}
    else
      {:noreply, assign(socket, payments_type: :none)}
    end
  end

  @impl true
  def handle_event("assign_due_date", %{"field" => field, "value" => date}, socket) do
    field = String.to_existing_atom(field)

    case Date.from_iso8601(date) do
      {:ok, date} ->
        {:noreply,
         assign(socket, message: nil, due_dates: Map.put(socket.assigns.due_dates, field, date))}

      {:error, _} ->
        {:noreply, assign(socket, message: "data inválida")}
    end
  end

  @impl true
  def handle_event("verify", %{"attrs" => params}, socket) do
    %{
      params: params,
      form_state: socket.assigns.form_state,
      payments_type: socket.assigns.payments_type,
      socket: socket
    }
    |> validate_params()
    |> build_opts()
    |> verify()
    |> handle_verify_return()
  end

  @impl true
  def handle_event("save", %{"attrs" => params}, socket) do
    %{
      params: params,
      form_state: socket.assigns.form_state,
      payments_type: socket.assigns.payments_type,
      socket: socket
    }
    |> validate_params()
    |> build_opts()
    |> create()
    |> handle_create_return()
  end

  @impl true
  def handle_event("form_change", %{"attrs" => params}, socket) do
    params = handle_sector_params(params)
    start_date = Date.from_iso8601!(params["start_date"])

    socket =
      socket
      |> assign(changeset: HR.batch_create_payslips_change(params))
      |> assign(message: nil)
      |> assign_payables_due_dates(start_date)
      |> assign_verify_return(nil)

    {:noreply, socket}
  end

  defp handle_sector_params(%{"sectors_ids" => sectors_ids} = params) do
    sectors_ids = Enum.reduce(sectors_ids, [], fn
      {sector, "on"}, acc -> [sector | acc]
      _, acc -> acc
    end)

    %{params | "sectors_ids" => sectors_ids}
  end

  defp handle_sector_params(params), do: params

  defp handle_submit_event([_ | _]), do: "save"
  defp handle_submit_event(_), do: "verify"

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Gerar Holerites em Lote" close={@close_event}>
      <Form
        for={@changeset}
        change="form_change"
        submit={handle_submit_event(@verified_registrations)}
        opts={autocomplete: "off"}
      >
        <Field  name={:start_date} class="flex-1">
          <Label class="form-label">Mês</Label>
          <Select
            options={@dates_for_select}
            selected={Date.to_iso8601(@selected_date)}
            class="form-input"
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:type} class="form-field">
          <Label class="form-label">Tipo</Label>
          <Select options={enum_for_select(PayslipGroupType)} class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <label class="form-label">Setores</label>

        <div class="grid grid-cols-2">
          {#for sector <- @sectors}
            <div class="form-checkbox-field">
              <input
                type="checkbox"
                class="form-checkbox"
                id={build_checkbox_name(sector.id)}
                name={build_checkbox_name(sector.id)}
                checked={checked_sector?(@changeset, sector.id)}
              />

              <label for={build_checkbox_name(sector.id)} class="form-side-label">
                {String.capitalize(sector.name)}
              </label>
            </div>
          {/for}
        </div>

        <div class="flex justify-start items-center mt-3">
          <Switch is_active={@payments_type != :none} toggle_is_active="handle_payments_type"/>

          <label class="form-side-label ml-2" :on-click="handle_payments_type">
            Criar pagamentos
          </label>
        </div>

        <div :if={@payments_type != :none} class="flex form-field space-x-3">
          <div class="flex-1">
            <label for="payment_advance_date" class="form-label">Adiantamentos</label>

            <input
              id="payment_advance_date"
              type="date"
              class="form-input"
              :on-blur="assign_due_date"
              phx-value-field="payment_advance_date"
              value={@due_dates.payment_advance_date}
            >
          </div>

          <div class="flex-1">
            <label for="salary_date" class="form-label">Salários</label>

            <input
              id="salary_date"
              type="date"
              class="form-input"
              :on-blur="assign_due_date"
              phx-value-field="salary_date"
              value={@due_dates.salary_date}
            >
          </div>
        </div>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div class="flex justify-between items-center">
          <div class="form-label">
            {#if @verified_registrations}
              {#case Enum.count(@verified_registrations)}
                {#match 1}
                  1 novo holerite será gerado
                {#match count}
                  {count} novos holerites serão gerados
              {/case}
            {/if}
          </div>

          <Submit
            class="btn-blue"
            label={handle_submit_btn_label(@verified_registrations)}
            opts={phx_disable_with: handle_submit_btn_disabled_msg(@verified_registrations)}
          />
        </div>

        <VerifiedRegistrations
          :if={@verified_registrations && @verified_registrations != []}
          registrations={@verified_registrations}
        />
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp build_dates_for_select(selected_date) do
    prior = selected_date |> Sig.Date.list_by_month(:prior, 2) |> Enum.reverse()
    next = Sig.Date.list_by_month(selected_date, :next, 3)

    dates = prior ++ [selected_date] ++ next

    Enum.map(dates, & {format_month(&1), Date.to_iso8601(&1)})
  end

  defp assign_payables_due_dates(socket, date) do
    payment_advance_date = %Date{date | day: 20} |> Sig.Date.adjust_for_workday()
    salary_date = date |> Sig.Date.next_month_start() |> Sig.Date.nth_workday(5)

    assign(socket, :due_dates, %{
      payment_advance_date: payment_advance_date,
      salary_date: salary_date
    })
  end

  defp validate_params(context) do
    context.params
    |> handle_sector_params()
    |> HR.batch_create_payslips_change()
    |> case do
      %{valid?: true} = changeset -> Map.put(context, :validation, {:ok, changeset})
      changeset -> Map.put(context, :validation, {:error, changeset})
    end
  end

  defp build_opts(%{payments_type: :none} = context), do: Map.put(context, :opts, [])

  defp build_opts(%{payments_type: :standard} = context) do
    opts = [
      payables_attrs: %{type: :standard, due_dates: context.socket.assigns.due_dates}
    ]

    Map.put(context, :opts, opts)
  end

  defp assign_verify_return(socket, [_ | _] = verified_registrations) do
    assign(socket, verified_registrations: verified_registrations)
  end

  defp assign_verify_return(socket, []) do
    assign(socket,
      verified_registrations: nil,
      message: "Não existem novos holerites deste tipo a serem gerados para este mês"
    )
  end

  defp assign_verify_return(socket, _verify_return) do
    assign(socket, verified_registrations: nil)
  end

  defp verify(%{validation: {:error, _}} = context), do: context

  defp verify(%{validation: {:ok, %{changes: changes}}} = context) do
    org = context.socket.assigns.org

    Map.put(context, :return, HR.verify_batch_create_payslips(org, changes))
  end

  defp handle_verify_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_verify_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_verify_return(%{return: {:error, changeset}} = context) when is_struct(changeset) do
    {:noreply, assign(context.socket, message: nil, changeset: changeset)}
  end

  defp handle_verify_return(%{return: {:ok, verified_registrations}} = context) do
    {:noreply,
      context.socket
      |> assign(message: nil)
      |> assign_verify_return(verified_registrations)}
  end

  defp create(%{validation: {:error, _}} = context), do: context

  defp create(%{validation: {:ok, changeset}} = context) do
    %{opts: opts, socket: %{assigns: %{org: org}}} = context

    Map.put(context, :return, HR.batch_create_payslips(org, changeset.changes, opts))
  end

  defp handle_create_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, verified_registrations: nil, changeset: changeset)}
  end

  defp handle_create_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, verified_registrations: nil, message: message, changeset: changeset)}
  end

  defp handle_create_return(%{return: {:error, changeset}} = context) when is_struct(changeset) do
    {:noreply, assign(context.socket, message: nil, verified_registrations: nil, changeset: changeset)}
  end

  defp handle_create_return(%{return: {:ok, payslips}, socket: socket}) do
    send(self(), {:flash, :info, "#{Enum.count(payslips)} holerites gerados"})
    socket.assigns.close_fun.()

    {:noreply, socket}
  end

  defp build_checkbox_name(name), do: "attrs[sectors_ids][#{name}]"

  defp checked_sector?(%{changes: %{sectors_ids: sectors_ids}}, sector_id) do
    sector_id in sectors_ids
  end

  defp checked_sector?(_changeset, _sector), do: true

  defp handle_submit_btn_label([_ | _]), do: "Gerar"
  defp handle_submit_btn_label(_), do: "Verificar"

  defp handle_submit_btn_disabled_msg([_ | _]), do: "Gerando..."
  defp handle_submit_btn_disabled_msg(_), do: "Verificando..."
end
