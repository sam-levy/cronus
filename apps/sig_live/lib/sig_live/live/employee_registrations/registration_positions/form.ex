defmodule SigLive.EmployeeRegistrations.RegistrationPositions.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Organizations

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Select,
    ErrorTag,
    Field,
    Label,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop registration, :struct, required: true
  prop registration_position_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, registration: registration, registration_position_id: registration_position_id} =
      assigns

    registration_position = get_registration_position(registration, registration_position_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        positions: Organizations.list_org_positions(org),
        registration_position: registration_position,
        changeset: set_changeset(registration_position)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"registration_position" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Novo Cargo" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:position_id} class="form-field">
          <Label class="form-label">Cargo</Label>
          <Select
            prompt=""
            options={id_by_name_for_select(@positions)}
            {...props_for(:position_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:start_date} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_registration_position(_registration, nil), do: nil

  defp get_registration_position(registration, registration_position_id) do
    HR.get_registration_position(registration, registration_position_id)
  end

  defp set_changeset(nil), do: HR.create_registration_position_change()

  defp set_changeset(registration_position) do
    HR.update_registration_position_change(registration_position)
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_registration_position_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{registration_position: registration_position} = context.socket.assigns

    changeset = HR.update_registration_position_change(registration_position, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_registration_position(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{registration_position: registration_position} = context.socket.assigns

    Map.put(
      context,
      :return,
      HR.update_registration_position(registration_position, changeset.changes)
    )
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

  defp handle_return(%{return: {:ok, _leave_period}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_updated_registration_positions(registration)
    flash_info("Cargo atualizado")
    close_fun.()

    {:noreply, socket}
  end

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, _form_state), do: @input_enabled
end
