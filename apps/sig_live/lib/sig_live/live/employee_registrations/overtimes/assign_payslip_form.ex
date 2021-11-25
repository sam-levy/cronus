defmodule SigLive.EmployeeRegistrations.Overtimes.AssignPayslipForm do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    Select,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:open, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop overtime_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, overtime_id: overtime_id} = assigns

    overtime = HR.get_overtime(registration, overtime_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        overtime: overtime,
        changeset: HR.assign_overtime_payslip_change(overtime),
        payslips: HR.list_payslips_by(registration, limit: 3)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"overtime" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Atribuir Holerite" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:payslip_id} class="form-field">
          <Label class="form-label">Holerite</Label>
          <Select options={payslips_for_select(@payslips)} class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp payslips_for_select(payslips) do
    Map.new(payslips, & {format_month(&1.start_date), &1.id})
  end

  defp validate_params(%{params: params} = context) do
    %{overtime: overtime} = context.socket.assigns
    changeset = HR.assign_overtime_payslip_change(overtime, params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{overtime: overtime} = context.socket.assigns

    Map.put(context, :return, HR.assign_overtime_payslip(overtime, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _overtime}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_overtimes(registration)
    send(self(), {:flash, :info, "Holerite atribuido"})
    close_fun.()

    {:noreply, socket}
  end
end
