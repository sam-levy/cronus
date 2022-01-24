defmodule SigLive.EmployeeRegistrations.Benefits.BenefitFromModelForm do
  use SigLive, :surface_live_component

  alias Sig.HR

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

  @form_states [:new_mode, :show_mode, :closed]

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
        changeset: set_changeset(benefit),
        benefit_models: HR.list_benefit_models(registration.org)
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
        <Field name={:start_date} class="form-field">
          <Label class="form-label">Data de Início</Label>
          <DateInput {...props_for(:start_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:benefit_model_id} class="form-field">
          <Label class="form-label">Modelo</Label>
          <Select
            prompt=""
            options={benefit_models_for_select(@benefit_models)}
            {...props_for(:benefit_model_id, @form_state)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:end_date} :if={@form_state != :new_mode} class="form-field">
          <Label class="form-label">Data de Término</Label>
          <DateInput {...props_for(:end_date, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:description} class="form-field">
          <Label class="form-label">
            Descrição

            <span :if={@form_state != :show_mode} class="form-label-complement">
              (opcional)
            </span>
          </Label>
          <TextInput {...props_for(:description, @form_state)} />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:is_for_dependent} class="form-checkbox-field">
          <Checkbox {...props_for_checkbox(:is_for_dependent, @form_state)} />
          <Label class="form-side-label">Para Dependente</Label>
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div :if={@form_state != :show_mode} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>

      <HistoricalAmounts
        :if={show_field?(:benefit_model_historical_amounts, @form_state, @benefit)}
        historical_amounts={@benefit.benefit_model.historical_amounts}
      />
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_benefit(_registration, nil), do: nil
  defp get_benefit(registration, benefit_id), do: HR.get_benefit(registration, benefit_id)

  defp set_changeset(nil), do: HR.create_benefit_from_model_change()
  # TODO: Add a proper changeset when implement edit
  defp set_changeset(benefit), do: HR.finalize_benefit_change(benefit)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("registration_id", "registration_id")
      |> HR.create_benefit_from_model_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(context, :return, HR.create_benefit_from_model(registration, changeset.changes))
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

  defp handle_flash(:new_mode), do: flash_info("Benefício criado")

  defp handle_title(:new_mode), do: "Adicionar Benefício de um Modelo"
  defp handle_title(:show_mode), do: "Benefício"

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  @checkbox_enabled [opts: [disabled: false], class: ["form-checkbox"]]
  @checkbox_disabled [opts: [disabled: true], class: ["form-checkbox-disabled"]]

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp props_for_checkbox(:is_for_dependent, :new_mode), do: @checkbox_enabled
  defp props_for_checkbox(:is_for_dependent, _form_state), do: @checkbox_disabled

  defp show_field?(:benefit_model_historical_amounts, :show_mode, %{
         is_from_model: true,
         benefit_model: %{historical_amounts: [_]}
       }) do
    false
  end

  defp show_field?(:benefit_model_historical_amounts, :show_mode, %{is_from_model: true}),
    do: true

  defp show_field?(:benefit_model_historical_amounts, :show_mode, _benefit), do: false

  defp show_field?(_field, _form_state, _benefit), do: false

  defp benefit_models_for_select(benefit_models) do
    Map.new(benefit_models, fn model ->
      key = "#{model.type} - #{model.description} - #{Money.to_string(model.amount)}"

      {key, model.id}
    end)
  end
end
