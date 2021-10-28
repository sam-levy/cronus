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

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop payslip_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, payslip_id: payslip_id} = assigns
    payslip = get_payslip(registration, payslip_id)
    selected_date = Sig.Date.next_month_start()

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payslip: payslip,
        changeset: set_changeset(payslip),
        dates: build_dates(),
        selected_date: selected_date
      )
      |> assign_changeset_dates(selected_date)

    {:ok, socket}
  end

  @impl true
  def handle_event("set_date_select_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :date_select_mode, String.to_existing_atom(mode))}
  end

  @impl true
  def handle_event("select_date", %{"value" => date}, socket) do
    date = Date.from_iso8601!(date)

    {:noreply, socket |> assign_changeset_dates(date) |> assign(:selected_date, date)}
  end

  @impl true
  def handle_event("save", %{"payslip" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <div class="form-field">
          <label for="month" class="form-label">Mês</label>

          <select name="month" class="form-input" :on-click="select_date">
            {#for date <- @dates}
              <option value={date} selected={date == @selected_date}>
                {format_month(date)}
              </option>
            {/for}
          </select>
        </div>

        <div  class="flex form-field space-x-3">
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
          <Select options={enum_for_select(PayslipGroupType)} selected={:regular} {...props_for(:type, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_payslip(_registration, nil), do: nil

  defp get_payslip(registration, payslip_id) do
    HR.get_payslip(registration, payslip_id)
  end

  defp set_changeset(nil), do: HR.create_payslip_change()
  # defp set_changeset(payslip), do: HR.update_payslip_change(payslip)

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

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    case HR.create_payslip(registration, changeset.changes) do
      {:ok, payslip} -> Map.put(context, :return, {:ok, payslip})
      {:error, error} -> Map.put(context, :return, {:error, error})
    end
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _registration}, socket: socket}) do
    %{registration: registration, form_state: form_state, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_payslips(registration)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Holerite criado"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Holerite atualizado"})

  defp handle_title(:new_mode), do: "Adicionar Holerite"
  defp handle_title(:edit_mode), do: "Editar Holerite"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp assign_changeset_dates(socket, date) do
    start_date = Date.beginning_of_month(date)
    end_date = Date.end_of_month(date)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:start_date, start_date)
      |> Ecto.Changeset.put_change(:end_date, end_date)

    assign(socket, :changeset, changeset)
  end

  defp build_dates do
    current = Date.utc_today() |> Date.beginning_of_month()

    Sig.Date.list_by_month(current, :prior, 1) ++
    [current] ++
    Sig.Date.list_by_month(current, :next, 3)
  end
end
