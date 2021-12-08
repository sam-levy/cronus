defmodule SigLive.EmployeeRegistrations.Payslips.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    ErrorTag,
    Field,
    Label,
    Select,
    Submit,
    DateInput
  }

  alias Sig.HR.Payslips.PayslipGroupType

  alias SigLive.Components.{Modal, Switch}

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop payslip_id, :string, default: nil

  data message, :string, default: nil
  data is_from_model, :boolean, default: true
  data payments_type, :atom, default: :standard, values: [:standard, :none]

  @impl true
  def update(assigns, socket) do
    %{registration: registration, payslip_id: payslip_id} = assigns

    payslip = get_payslip(registration, payslip_id)
    selected_date = set_selected_date(payslip)
    changeset = set_changeset(payslip)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payslip: payslip,
        changeset: changeset,
        dates_for_select: build_dates_for_select(selected_date, registration.admission_date),
        selected_date: selected_date,
        selected_type: set_selected_type(changeset)
      )
      |> assign_changeset_dates(selected_date)
      |> assign_payables_due_dates(selected_date)

    {:ok, socket}
  end

  @impl true
  def handle_event("set_date_select_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :date_select_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event("select_date", %{"value" => date}, socket) do
    date = Date.from_iso8601!(date)

    {:noreply,
     socket
     |> assign_changeset_dates(date)
     |> assign(:selected_date, date)
     |> assign_payables_due_dates(date)}
  end

  @impl true
  def handle_event("toggle_is_from_model", _params, socket) do
    if socket.assigns.is_from_model do
      {:noreply, assign(socket, is_from_model: false, payments_type: :none)}
    else
      {:noreply, assign(socket, is_from_model: true, payments_type: :standard)}
    end
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
  def handle_event("save", %{"payslip" => params}, socket) do
    %{
      params: params,
      form_state: socket.assigns.form_state,
      is_from_model: socket.assigns.is_from_model,
      payments_type: socket.assigns.payments_type,
      socket: socket
    }
    |> validate_params()
    |> build_payslip_opts()
    |> persist()
    |> handle_return()
  end

  @impl true
  def handle_event("form_change", %{"payslip" => params}, socket) do
    {:noreply, assign(socket, changeset: HR.create_payslip_change(params))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} change="form_change" submit="save" opts={autocomplete: "off"}>
        <div class="form-field">
          <label for="month" class="form-label">Mês</label>

          <select name="month" class="form-input" :on-click="select_date">
            {#for date <- @dates_for_select}
              <option value={date} selected={date == @selected_date}>
                {format_month(date)}
              </option>
            {/for}
          </select>
        </div>

        <div class="flex form-field space-x-3">
          <Field  name={:start_date} class="flex-1">
            <Label class="form-label">Início do Período</Label>
            <DateInput {...props_for(:start_date, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>

          <Field name={:end_date} class="flex-1">
            <Label class="form-label">Final do Período</Label>
            <DateInput {...props_for(:end_date, @form_state)}/>
            <ErrorTag class="form-error-tag"/>
          </Field>
        </div>

        <Field name={:type} class="form-field">
          <Label class="form-label">Tipo</Label>
          <Select
            options={enum_for_select(PayslipGroupType)}
            selected={@selected_type}
            {...props_for(:type, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@form_state == :new_mode} class="flex justify-start items-center">
          <Switch is_active={@is_from_model} toggle_is_active="toggle_is_from_model"/>

          <label class="form-side-label ml-2":on-click="toggle_is_from_model">
            Criar a partir do modelo
          </label>
        </div>

        <div :if={@form_state == :new_mode and @is_from_model} class="flex justify-start items-center mt-3">
          <Switch is_active={@payments_type != :none} toggle_is_active="handle_payments_type"/>

          <label class="form-side-label ml-2":on-click="handle_payments_type">
            Criar pagamentos
          </label>
        </div>

        <div :if={@form_state == :new_mode and @payments_type != :none} class="flex form-field space-x-3">
          <div class="flex-1">
            <label for="payment_advance_date" class="form-label">Adiantamento</label>

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
            <label for="salary_date" class="form-label">Salário</label>

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

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_payslip(_registration, nil), do: nil
  defp get_payslip(registration, payslip_id), do: HR.get_payslip(registration, payslip_id)

  defp set_selected_date(nil), do: Sig.Date.next_month_start()
  defp set_selected_date(payslip), do: payslip.start_date

  defp set_changeset(nil), do: HR.create_payslip_change()
  defp set_changeset(payslip), do: HR.update_payslip_change(payslip)

  defp set_selected_type(%{data: %{type: nil}}), do: :regular
  defp set_selected_type(%{data: %{type: type}}), do: type

  defp assign_changeset_dates(%{assigns: %{changeset: %{data: %{start_date: nil}}}} = socket, date) do
    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:start_date, Date.beginning_of_month(date))
      |> Ecto.Changeset.put_change(:end_date, Date.end_of_month(date))

    assign(socket, :changeset, changeset)
  end

  defp assign_changeset_dates(socket, _date), do: socket

  defp assign_payables_due_dates(socket, date) do
    payment_advance_date = %Date{date | day: 20} |> Sig.Date.adjust_for_workday()
    salary_date = date |> Sig.Date.next_month_start() |> Sig.Date.nth_workday(5)

    assign(socket, :due_dates, %{
      payment_advance_date: payment_advance_date,
      salary_date: salary_date
    })
  end

  defp build_dates_for_select(selected_date, floor_date) do
    prior = selected_date |> Sig.Date.list_by_month(:prior, 3) |> Enum.reverse()
    next = Sig.Date.list_by_month(selected_date, :next, 3)

    dates = prior ++ [selected_date] ++ next

    Enum.reject(dates, fn date -> Date.compare(date, floor_date) == :lt end)
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_payslip_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{payslip: payslip} = context.socket.assigns
    changeset = HR.update_payslip_change(payslip, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(
         %{validation: {:ok, changeset}, form_state: :new_mode, is_from_model: true} = context
       ) do
    %{payslip_opts: payslip_opts, socket: %{assigns: %{registration: registration}}} = context

    Map.put(
      context,
      :return,
      HR.create_payslip_from_model(registration, changeset.changes, payslip_opts)
    )
  end

  defp persist(
         %{validation: {:ok, changeset}, form_state: :new_mode, is_from_model: false} = context
       ) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{payslip: payslip} = context.socket.assigns

    Map.put(context, :return, HR.update_payslip(payslip, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) when is_struct(changeset) do
    {:noreply, assign(context.socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, payslip}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, payslip, socket)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, payslip, _socket) do
    HR.broadcast_new_payslip(payslip, refetch: true, preload_registration: true)
  end

  defp handle_broadcast(:edit_mode, payslip, socket) do
    %{payslip: old_payslip} = socket.assigns

    HR.broadcast_updated_payslip(payslip, old_payslip, refetch: true, preload_registration: true)
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Holerite criado"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Holerite atualizado"})

  defp handle_title(:new_mode), do: "Adicionar Holerite"
  defp handle_title(:edit_mode), do: "Editar Holerite"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(:start_date, :edit_mode), do: @input_enabled
  defp props_for(:end_date, :edit_mode), do: @input_enabled
  defp props_for(:type, :edit_mode), do: @input_enabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp build_payslip_opts(%{is_from_model: false} = context) do
    Map.put(context, :payslip_opts, [])
  end

  defp build_payslip_opts(%{payments_type: :none} = context) do
    Map.put(context, :payslip_opts, [])
  end

  defp build_payslip_opts(%{payments_type: :standard} = context) do
    payslip_opts = [
      payables_attrs: %{type: :standard, due_dates: context.socket.assigns.due_dates}
    ]

    Map.put(context, :payslip_opts, payslip_opts)
  end
end
