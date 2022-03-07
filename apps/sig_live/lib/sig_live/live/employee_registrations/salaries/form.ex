defmodule SigLive.EmployeeRegistrations.Salaries.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
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
  prop registration, :struct, required: true
  prop salary_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, salary_id: salary_id} = assigns

    salary = get_salary(registration, salary_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        salary: salary,
        changeset: set_changeset(salary)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"salary" => params}, socket) do
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
        <Field name={:start_date}>
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput class="form-input" value={format_salary_amount(@changeset)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Atualizando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  defp handle_title(:new_mode), do: "Novo Salário"
  defp handle_title(:edit_mode), do: "Editar Salário"

  def states, do: @form_states

  defp get_salary(_registration, nil), do: nil
  defp get_salary(registration, salary_id), do: HR.get_salary(registration, salary_id)

  defp set_changeset(nil), do: HR.create_salary_change()
  defp set_changeset(salary), do: HR.update_salary_change(salary)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_salary_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{salary: salary} = context.socket.assigns

    changeset = HR.update_salary_change(salary, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_salary(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{salary: salary} = context.socket.assigns

    Map.put(context, :return, HR.update_salary(salary, changeset.changes))
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

  defp handle_return(%{return: {:ok, _salary}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_salaries(registration)
    HR.broadcast_registration_recurring_payslip_items(registration)

    flash_info("Salário atualizado")
    close_fun.()

    {:noreply, socket}
  end

  defp format_salary_amount(%{changes: %{amount: amount}}), do: format_amount(amount)
  defp format_salary_amount(_), do: ""

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_focused [opts: [disabled: false, phx_hook: "FocusElement"], class: ["form-input"]]

  defp props_for(:start_date, :new_mode), do: @input_focused
  defp props_for(:start_date, :edit_mode), do: @input_enabled
end
