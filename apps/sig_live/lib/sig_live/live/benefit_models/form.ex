defmodule SigLive.BenefitModels.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.HR.BenefitModels.BenefitType

  alias Surface.Components.Form
  alias SigLive.Components.HistoricalAmounts

  alias Surface.Components.Form.{
    TextInput,
    DateInput,
    Select,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :edit_amount_mode, :disable_mode, :show_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop benefit_model_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, benefit_model_id: id, form_state: form_state} = assigns

    benefit_model = get_benefit_model(org, id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        benefit_model: benefit_model,
        changeset: set_changeset(form_state, benefit_model)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"benefit_model" => params}, socket) do
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
        <Field name={:description} :if={show_field?(:description, @form_state)} class="form-field">
          <Label class="form-label">Descrição</Label>
          <TextInput {...props_for(:description, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:type} :if={show_field?(:type, @form_state)} class="form-field">
          <Label class="form-label">Tipo</Label>
          <Select options={enum_for_select(BenefitType)} prompt="" {...props_for(:type, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:amount} :if={show_field?(:amount, @form_state)} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput value={format_benefit_model_amount(@changeset)} {...props_for(:amount, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:amount_date} :if={show_field?(:amount_date, @form_state)} class="form-field">
          <Label class="form-label">Data de Início do Valor</Label>
          <DateInput {...props_for(:amount_date, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <HistoricalAmounts
          :if={show_field?(:historical_amounts, @form_state, @benefit_model)}
          historical_amounts={@benefit_model.historical_amounts}
        />

        <Field name={:disabled_at} :if={show_field?(:disabled_at, @form_state, @benefit_model)} class="form-field">
          <Label class="form-label">Data de Desativação</Label>
          <DateInput {...props_for(:disabled_at, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div :if={show_field?(:submit, @form_state)} class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_benefit_model(_org, nil), do: nil
  defp get_benefit_model(org, benefit_model_id), do: HR.get_benefit_model(org, benefit_model_id)

  defp set_changeset(:new_mode, _), do: HR.create_benefit_model_change()
  defp set_changeset(:show_mode, benefit_model), do: HR.update_benefit_model_change(benefit_model)

  defp set_changeset(:edit_mode, benefit_model), do: HR.update_benefit_model_change(benefit_model)
  defp set_changeset(:edit_amount_mode, benefit_model), do: HR.update_benefit_model_amount_change(benefit_model)
  defp set_changeset(:disable_mode, benefit_model), do: HR.disable_benefit_model_change(benefit_model)

  defp set_changeset(:edit_mode, benefit_model, params), do: HR.update_benefit_model_change(benefit_model, params)
  defp set_changeset(:edit_amount_mode, benefit_model, params), do: HR.update_benefit_model_amount_change(benefit_model, params)
  defp set_changeset(:disable_mode, benefit_model, params), do: HR.disable_benefit_model_change(benefit_model, params)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> HR.create_benefit_model_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: form_state} = context) do
    %{benefit_model: benefit_model} = context.socket.assigns

    changeset = set_changeset(form_state, benefit_model, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org} = context.socket.assigns

    Map.put(context, :return, HR.create_benefit_model(org, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{benefit_model: benefit_model} = context.socket.assigns

    Map.put(context, :return, HR.update_benefit_model(benefit_model, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_amount_mode} = context) do
    %{benefit_model: benefit_model} = context.socket.assigns

    Map.put(context, :return, HR.update_benefit_model_amount(benefit_model, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :disable_mode} = context) do
    %{benefit_model: benefit_model} = context.socket.assigns

    Map.put(context, :return, HR.disable_benefit_model(benefit_model, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, benefit_model}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, benefit_model)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, benefit_model) do
    HR.broadcast_new_benefit_model(benefit_model)
  end

  defp handle_broadcast(_mode, benefit_model) do
    HR.broadcast_updated_benefit_model(benefit_model)
  end

  defp handle_flash(:new_mode), do: flash_info("Modelo de benefício criado")
  defp handle_flash(_), do: flash_info("Modelo de benefício alterado")

  defp handle_title(:show_mode), do: "Modelo de Benefício"
  defp handle_title(:new_mode), do: "Novo Modelo de Benefício"
  defp handle_title(:edit_mode), do: "Renomear Modelo de Benefício"
  defp handle_title(:edit_amount_mode), do: "Atualizar o Valor do Modelo de Benefício"
  defp handle_title(:disable_mode), do: "Desativar Modelo de Benefício"

  defp format_benefit_model_amount(%{changes: %{amount: amount}}), do: format_amount(amount)
  defp format_benefit_model_amount(%{data: %{amount: amount}}), do: format_amount(amount)
  defp format_benefit_model_amount(_), do: ""

  defp show_field?(:description, :edit_amount_mode), do: false
  defp show_field?(:description, :disable_mode), do: false
  defp show_field?(:description, _mode), do: true

  defp show_field?(:type, :edit_amount_mode), do: false
  defp show_field?(:type, :disable_mode), do: false
  defp show_field?(:type, _mode), do: true

  defp show_field?(:amount, :edit_mode), do: false
  defp show_field?(:amount, :disable_mode), do: false
  defp show_field?(:amount, _mode), do: true

  defp show_field?(:amount_date, :new_mode), do: true
  defp show_field?(:amount_date, :edit_amount_mode), do: true
  defp show_field?(:amount_date, _mode), do: false

  defp show_field?(:submit, :show_mode), do: false
  defp show_field?(:submit, _mode), do: true

  defp show_field?(:disabled_at, :show_mode, %{disabled_at: %Date{}}), do: true
  defp show_field?(:disabled_at, :disable_mode, %{disabled_at: nil}), do: true
  defp show_field?(:disabled_at, _mode, _benefit_model), do: false

  defp show_field?(:historical_amounts, :show_mode, %{historical_amounts: [_ | _]}), do: true
  defp show_field?(:historical_amounts, _mode, _benefit_model), do: false

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  defp props_for(:description, :new_mode), do: @input_enabled
  defp props_for(:description, :edit_mode), do: @input_enabled
  defp props_for(:description, _mode), do: @input_disabled

  defp props_for(:type, :new_mode), do: @input_enabled
  defp props_for(:type, :edit_mode), do: @input_enabled
  defp props_for(:type, _mode), do: @input_disabled

  defp props_for(:amount, :new_mode), do: @input_enabled
  defp props_for(:amount, :edit_amount_mode), do: @input_enabled
  defp props_for(:amount, _mode), do: @input_disabled

  defp props_for(:amount_date, :new_mode), do: @input_enabled
  defp props_for(:amount_date, :edit_amount_mode), do: @input_enabled
  defp props_for(:amount_date, _mode), do: @input_disabled

  defp props_for(:disabled_at, :disable_mode), do: @input_enabled
  defp props_for(:disabled_at, _mode), do: @input_disabled
end
