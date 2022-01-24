defmodule SigLive.EmployeeRegistrations.LeavePeriods.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

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

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop registration, :struct, required: true
  prop leave_period_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, leave_period_id: leave_period_id} = assigns
    leave_period = get_leave_period(registration, leave_period_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        leave_period: leave_period,
        changeset: set_changeset(leave_period)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"leave_period" => params}, socket) do
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
        <Field name={:type} class="form-field">
          <Label class="form-label">Tipo</Label>
          <Select
            prompt=""
            options={list_for_select(HR.list_leave_period_types())}
            {...props_for(:type, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:start_date} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:end_date} class="form-field">
          <Label class="form-label">Data de Término</Label>
          <DateInput {...props_for(:end_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_leave_period(_registration, nil), do: nil

  defp get_leave_period(registration, leave_period_id) do
    HR.get_leave_period(registration, leave_period_id)
  end

  defp set_changeset(nil), do: HR.create_leave_period_change()
  defp set_changeset(leave_period), do: HR.update_leave_period_change(leave_period)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_leave_period_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{leave_period: leave_period} = context.socket.assigns
    changeset = HR.update_leave_period_change(leave_period, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_leave_period(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{leave_period: leave_period} = context.socket.assigns

    Map.put(context, :return, HR.update_leave_period(leave_period, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _leave_period}, socket: socket}) do
    %{registration: registration, form_state: form_state, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_leave_periods(registration)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_flash(:new_mode), do: flash_info("Licença adicionada")
  defp handle_flash(:edit_mode), do: flash_info("Licença alterada")

  defp handle_title(:new_mode), do: "Adicionar Licença"
  defp handle_title(:edit_mode), do: "Editar Licença"
  defp handle_title(:show_mode), do: "Licença"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(_field, :show_mode), do: @input_disabled
  defp props_for(_field, _form_state), do: @input_enabled
end
