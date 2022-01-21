defmodule SigLive.EmployeeRegistrations.RecurringPayslipItems.CreateFromPayslipTemplateForm do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
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
  prop registration, :struct, required: true

  data message, :string, default: nil

  @impl true
  def handle_event("save", %{"payslip_template" => %{"payslip_template_id" => id}}, socket) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    case HR.create_recurring_payslip_items_from_template(registration, id) do
      {:ok, _} ->
        HR.broadcast_registration_recurring_payslip_items(registration)
        flash_info("Items criados")
        close_fun.()

        {:noreply, socket}

      error -> handle_error(error, socket)
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Importar Modelo de Holerite" close={@close_event}>
      <Form for={:payslip_template} submit="save" opts={autocomplete: "off"}>
        <Field name={:payslip_template_id} class="form-field">
          <Label class="form-label">Modelo de Holerite</Label>
          <Select
            prompt=""
            options={payslip_templates_for_select(@registration.org)}
            class="form-input"
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@message} class="form-error-tag">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp handle_error({:error, message}, socket) when is_binary(message) do
    {:noreply, assign(socket, message: message)}
  end

  defp handle_error({:error, changeset}, socket) when is_struct(changeset) do
    {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
  end

  defp payslip_templates_for_select(org) do
    org
    |> HR.list_payslip_templates()
    |> Map.new(&{&1.name, &1.id})
  end
end
