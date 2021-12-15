defmodule SigLive.EmployeeRegistrations.Benefits.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.HR.BenefitModels.BenefitType

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    Select,
    Checkbox,
    ErrorTag,
    Field,
    Label,
    Submit,
    DateInput
  }

  alias SigLive.Components.Modal
  alias SigLive.Components.HistoricalAmounts

  @form_states [:new_mode, :show_mode, :edit_amount_mode, :finalize_mode, :closed]

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
        <Field name={:start_date} :if={show_field?(:start_date, @form_state)} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:benefit_type} :if={show_field?(:benefit_type, @form_state)} class="form-field">
          <Label class="form-label">Benefício</Label>
          <Select
            prompt=""
            options={enum_for_select(BenefitType)}
            {...props_for(:benefit_type, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:benefit_amount} :if={show_field?(:benefit_amount, @form_state)} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput value={format_benefit_amount(@changeset)} {...props_for(:benefit_amount, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:benefit_amount_date} :if={show_field?(:benefit_amount_date, @form_state)} class="form-field">
          <Label class="form-label">Data de Início do Novo Valor</Label>
          <DateInput {...props_for(:benefit_amount_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:end_date} :if={show_field?(:end_date, @form_state)} class="form-field">
          <Label class="form-label">Data de Término</Label>
          <DateInput {...props_for(:end_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:description} :if={show_field?(:description, @form_state)} class="form-field">
          <Label class="form-label">
            Descrição

            <span :if={@form_state != :show_mode} class="form-label-complement">
              (opcional)
            </span>
          </Label>
          <TextInput {...props_for(:description, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:is_for_dependent} :if={show_field?(:is_for_dependent, @form_state)} class="form-checkbox-field">
          <Checkbox {...props_for_checkbox(:is_for_dependent, @form_state)}/>
          <Label class="form-side-label">Para Dependente</Label>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div :if={show_field?(:submit, @form_state)} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>

      <HistoricalAmounts
        :if={show_field?(:benefit_historical_amounts, @form_state, @benefit)}
        historical_amounts={@benefit.benefit_historical_amounts}
      />
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_benefit(_registration, nil), do: nil
  defp get_benefit(registration, benefit_id), do: HR.get_benefit(registration, benefit_id)

  defp set_changeset(nil), do: HR.create_benefit_change()
  defp set_changeset(benefit), do: HR.finalize_benefit_change(benefit)

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

  defp validate_params(%{form_state: :finalize_mode} = context) do
    %{benefit: benefit} = context.socket.assigns
    changeset = HR.finalize_benefit_change(benefit, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_amount_mode} = context) do
    %{benefit: benefit} = context.socket.assigns
    changeset = HR.update_benefit_amount_change(benefit, context.params)

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

  defp persist(%{validation: {:ok, changeset}, form_state: :finalize_mode} = context) do
    %{benefit: benefit} = context.socket.assigns

    Map.put(context, :return, HR.finalize_benefit(benefit, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_amount_mode} = context) do
    %{benefit: benefit} = context.socket.assigns

    Map.put(context, :return, HR.update_benefit_amount(benefit, changeset.changes))
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
  defp handle_flash(:finalize_mode), do: send(self(), {:flash, :info, "Benefício finalizado"})
  defp handle_flash(_), do: send(self(), {:flash, :info, "Benefício atualizado"})

  defp handle_title(:new_mode), do: "Adicionar Benefício"
  defp handle_title(:show_mode), do: "Benefício"
  defp handle_title(:edit_amount_mode), do: "Alterar Valor"
  defp handle_title(:finalize_mode), do: "Finalizar Benefício"

  defp show_field?(:benefit_amount, :edit_amount_mode), do: true

  defp show_field?(:benefit_amount_date, :edit_amount_mode), do: true
  defp show_field?(:benefit_amount_date, _form_state), do: false

  defp show_field?(:end_date, :finalize_mode), do: true
  defp show_field?(:end_date, _form_state), do: false

  defp show_field?(:submit, :show_mode), do: false
  defp show_field?(:submit, _form_state), do: true

  defp show_field?(_field, :new_mode), do: true
  defp show_field?(_field, :show_mode), do: true
  defp show_field?(_field, _form_state), do: false

  defp show_field?(:benefit_historical_amounts, :show_mode, %{is_from_model: false, benefit_historical_amounts: [_]}) do
    false
  end

  defp show_field?(:benefit_historical_amounts, :show_mode, %{is_from_model: false}), do: true
  defp show_field?(:benefit_historical_amounts, :show_mode, _benefit), do: false

  defp show_field?(:benefit_historical_amounts, :edit_amount_mode, _benefit), do: true
  defp show_field?(:benefit_historical_amounts, _form_state, _benefit), do: false

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  @checkbox_enabled [opts: [disabled: false], class: ["form-checkbox"]]
  @checkbox_disabled [opts: [disabled: true], class: ["form-checkbox-disabled"]]

  defp props_for(:benefit_amount, :edit_amount_mode), do: @input_enabled

  defp props_for(:benefit_amount_date, :edit_amount_mode), do: @input_enabled

  defp props_for(:end_date, :finalize_mode), do: @input_enabled
  defp props_for(:end_date, _form_state), do: @input_disabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp props_for_checkbox(:is_for_dependent, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox(:is_for_dependent, _form_state), do: @checkbox_disabled
end
