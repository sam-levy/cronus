defmodule SigLive.EmployeeRegistrations.ResignationForm do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.HR.Registrations.Registration.ResignationType

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    ErrorTag,
    Field,
    Label,
    Select,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @broadcast_opts [preload: [:registered_at]]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop individual, :struct, required: true
  prop registration_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{individual: individual, registration_id: registration_id} = assigns
    registration = HR.get_registration(individual, registration_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        registration: registration,
        changeset: HR.registration_resignation_change(registration)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"registration" => params}, socket) do
    %{registration: registration, individual: individual, close_fun: close_fun} = socket.assigns

    changeset = HR.registration_resignation_change(registration, params)

    with {:ok, _registration} <- apply_action(changeset, :update),
         {:ok, registration} <- HR.resign_registration(registration, changeset.changes) do
      HR.broadcast_updated_individual_registration(individual, registration, @broadcast_opts)
      flash_info("Desligamento efetuado")
      close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} when is_struct(changeset) ->
        {:noreply,
         assign(socket, changeset: changeset, message: Sig.Changeset.errors_to_string(changeset))}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, changeset: changeset, message: message)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Desligar Funcionário" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:resignation_date}>
          <Label class="form-label">Data de Desligamento</Label>
          <DateInput class="form-input" opts={phx_hook: "FocusElement"}/>
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:resignation_type} class="form-field">
          <Label class="form-label">Motivo do Desligamento</Label>
          <Select options={enum_for_select(ResignationType)} prompt="" class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Adicionando..."} />
        </div>
      </Form>
    </Modal>
    """
  end
end
