defmodule SigLive.EmployeeRegistrations.Warnings.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextArea,
    ErrorTag,
    Field,
    Label,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop warning_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, warning_id: warning_id} = assigns
    warning = get_warning(registration, warning_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        warning: warning,
        changeset: set_changeset(warning)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"warning" => params}, socket) do
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
        <Field name={:description} class="form-field">
          <Label class="form-label">Motivo</Label>
          <TextArea {...props_for(:description, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:date} class="form-field">
          <Label class="form-label">Data</Label>
          <DateInput {...props_for(:date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_warning(_registration, nil), do: nil
  defp get_warning(registration, warning_id), do: HR.get_warning(registration, warning_id)

  defp set_changeset(nil), do: HR.create_warning_change()
  defp set_changeset(warning), do: HR.update_warning_change(warning)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_warning_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{warning: warning} = context.socket.assigns
    changeset = HR.update_warning_change(warning, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_warning(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{warning: warning} = context.socket.assigns

    Map.put(context, :return, HR.update_warning(warning, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _warning}, socket: socket}) do
    %{registration: registration, form_state: form_state, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_warnings(registration)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Advertência criada"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Advertência alterada"})

  defp handle_title(:new_mode), do: "Nova Advertência"
  defp handle_title(:edit_mode), do: "Editar Advertência"
  defp handle_title(:show_mode), do: "Advertência"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, :show_mode), do: @input_disabled
  defp props_for(_field, _form_state), do: @input_enabled
end
