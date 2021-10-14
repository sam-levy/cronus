defmodule SigLive.EmployeeRegistrations.Benefits.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
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
  prop benefit_id, :string, default: nil

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{registration: registration, benefit_id: benefit_id} = assigns
    benefit = get_benefit(registration, benefit_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        benefit: benefit,
        changeset: set_changeset(benefit)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"benefit" => params}, socket) do
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
        <Field name={:start_date} :if={@form_state != :edit_mode} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:type} :if={@form_state != :edit_mode} class="form-field">
          <Label class="form-label">Benefício</Label>
          <Select
            prompt=""
            options={HR.list_benefit_types}
            {...props_for(:type, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:amount} :if={@form_state != :edit_mode} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput
            value={format_benefit_amount(@changeset)}
            {...props_for(:amount, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:end_date} :if={@form_state != :new_mode} class="form-field">
          <Label class="form-label">Data de Término</Label>
          <DateInput {...props_for(:end_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_benefit(_registration, nil), do: nil
  defp get_benefit(registration, benefit_id), do: HR.get_benefit(registration, benefit_id)

  defp set_changeset(nil), do: HR.create_benefit_change()
  defp set_changeset(benefit), do: HR.update_benefit_change(benefit)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_benefit_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{benefit: benefit} = context.socket.assigns
    changeset = HR.update_benefit_change(benefit, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_benefit(registration, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{benefit: benefit} = context.socket.assigns

    Map.put(context, :return, HR.update_benefit(benefit, changeset.changes))
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

  defp handle_return(%{return: {:ok, _benefit}, socket: socket}) do
    %{registration: registration, form_state: form_state, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_benefits(registration)
    HR.broadcast_registration_recurring_payslip_items(registration)

    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp format_benefit_amount(%{changes: %{amount: amount}}), do: format_amount(amount)
  defp format_benefit_amount(_), do: ""

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Benefício criado"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Benefício alterado"})

  defp handle_title(:new_mode), do: "Adicionar Benefício"
  defp handle_title(:edit_mode), do: "Finalizar Benefício"
  defp handle_title(:show_mode), do: "Benefício"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(:end_date, :edit_mode), do: @input_enabled
  defp props_for(:end_date, _form_state), do: @input_disabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled
end
