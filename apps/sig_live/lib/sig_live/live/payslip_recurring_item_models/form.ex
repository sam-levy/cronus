defmodule SigLive.PayslipRecurringItemModels.Form do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.HR.BenefitModels.BenefitType
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel.PercentageTarget

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    RadioButton,
    Select,
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop org, :struct, required: true
  prop payslip_recurring_item_model_id, :string, default: nil
  prop form_state, :atom, required: true, values!: @form_states
  prop close_event, :event, required: true
  prop close_fun, :fun, required: true

  @impl true
  def update(assigns, socket) do
    %{org: org, payslip_recurring_item_model_id: payslip_recurring_item_model_id} = assigns

    item_model = get_item_model(org, payslip_recurring_item_model_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        categories: HR.list_payslip_categories(org.id),
        item_model: item_model,
        changeset: set_changeset(item_model)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"recurring_item_model" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def handle_event("form_change", %{"recurring_item_model" => params}, socket) do
    case socket.assigns.form_state do
      :new_mode ->
        changeset = HR.create_payslip_recurring_item_model_change(params)

        {:noreply, assign(socket, changeset: changeset)}

      :edit_mode ->
        changeset = HR.update_payslip_recurring_item_model_change(socket.assigns.item_model, params)

        {:noreply, assign(socket, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end

  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} change="form_change" submit="save" opts={autocomplete: "off"}>
        <Field name={:description} class="form-field">
          <Label class="form-label">Nome</Label>
          <TextInput {...props_for(:description, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:category_id} class="form-field">
          <Label class="form-label">Categoria</Label>
          <Select
            prompt=""
            options={payslip_categories_for_select(@categories)}
            {...props_for(:category_id, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:is_fixed_amount} class="form-field flex gap-6">
          <label class="form-side-label" for="is_fixed_amount_true">
            <RadioButton
              value="true"
              id="is_fixed_amount_true"
              checked={is_fixed_amount?(@changeset)}
              {...radio_props_for(:is_fixed_amount, @form_state)}
            />
            Valor Fixo
          </label>

          <label class="form-side-label" for="is_fixed_amount_false">
            <RadioButton
              value="false"
              id="is_fixed_amount_false"
              checked={is_fixed_amount?(@changeset) == false}
              {...radio_props_for(:is_fixed_amount, @form_state)}
            />
             Valor Variável
          </label>
        </Field>

        <Field :if={show_field?(:amount, @changeset)} name={:amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput {...props_for(:amount, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field
          :if={show_field?(:percentage_target, @changeset)}
          name={:percentage_target}
          class="form-field"
        >
          <Label class="form-label">Base</Label>
          <Select
            prompt=""
            options={enum_for_select(PercentageTarget)}
            {...props_for(:percentage_target, @form_state)}
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field :if={show_field?(:percentage, @changeset)} name={:percentage} class="form-field">
          <Label class="form-label">Percentual</Label>
          <TextInput {...props_for(:percentage, @form_state)}/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field
          :if={show_field?(:employee_benefit_type_percentage_target, @changeset)}
          name={:employee_benefit_type_percentage_target}
          class="form-field"
        >
          <Label class="form-label">Benefício</Label>
          <Select
            prompt=""
            options={enum_for_select(BenefitType)}
            {...props_for(:employee_benefit_type_percentage_target, @form_state)}
          />
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

  defp get_item_model(_org, nil), do: nil

  defp get_item_model(org, payslip_recurring_item_model_id) do
    HR.get_payslip_recurring_item_model(org, payslip_recurring_item_model_id)
  end

  defp set_changeset(nil) do
    HR.create_payslip_recurring_item_model_change(%{is_fixed_amount: true})
  end

  defp set_changeset(item_model)do
    HR.update_payslip_recurring_item_model_change(item_model)
  end

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> HR.create_payslip_recurring_item_model_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{item_model: item_model} = context.socket.assigns

    changeset = HR.update_payslip_recurring_item_model_change(item_model, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip_recurring_item_model(org, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{item_model: item_model} = context.socket.assigns

    Map.put(context, :return, HR.update_payslip_recurring_item_model(item_model, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, item_model}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, item_model)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, item_model) do
    HR.broadcast_new_payslip_recurring_item_model(item_model, refetch: true)
  end

  defp handle_broadcast(:edit_mode, item_model) do
    HR.broadcast_updated_payslip_recurring_item_model(item_model, refetch: true)
  end

  defp handle_flash(:new_mode), do: flash_info("Modelo criado")
  defp handle_flash(:edit_mode), do: flash_info("Modelo alterado")

  defp handle_title(:new_mode), do: "Novo Modelo de Item Recorrente de Holerite"
  defp handle_title(:edit_mode), do: "Editar Modelo de Item Recorrente de Holerite"
  defp handle_title(:show_mode), do: "Modelo de Item Recorrente de Holerite"

  defp show_field?(:amount, %{changes: %{is_fixed_amount: true}}), do: true
  defp show_field?(:amount, %{data: %{is_fixed_amount: true}}), do: true
  defp show_field?(:amount, _), do: false

  defp show_field?(:percentage, %{changes: %{is_fixed_amount: true}}), do: false
  defp show_field?(:percentage, %{data: %{is_fixed_amount: true}}), do: false
  defp show_field?(:percentage, _), do: true

  defp show_field?(:percentage_target, %{changes: %{is_fixed_amount: true}}), do: false
  defp show_field?(:percentage_target, %{data: %{is_fixed_amount: true}}), do: false
  defp show_field?(:percentage_target, _), do: true

  defp show_field?(:employee_benefit_type_percentage_target, %{changes: %{percentage_target: :employee_benefit}}), do: true
  defp show_field?(:employee_benefit_type_percentage_target, %{data: %{percentage_target: :employee_benefit}}), do: true
  defp show_field?(:employee_benefit_type_percentage_target, _), do: false

  defp is_fixed_amount?(%{changes: %{is_fixed_amount: is_fixed_amount}}), do: is_fixed_amount
  defp is_fixed_amount?(%{data: %{is_fixed_amount: is_fixed_amount}}), do: is_fixed_amount
  defp is_fixed_amount?(_), do: false

  @input_enabled [opts: [disabled: false], class: ["form-input"]]
  @input_disabled [opts: [disabled: true], class: ["form-input-disabled"]]

  @radio_enabled [opts: [disabled: false], class: ["form-radio"]]
  @radio_disabled [opts: [disabled: true], class: ["form-radio-disabled"]]

  defp props_for(:description, :edit_mode), do: @input_enabled
  defp props_for(:amount, :edit_mode), do: @input_enabled
  defp props_for(:percentage, :edit_mode), do: @input_enabled

  defp props_for(_field, :new_mode), do: @input_enabled
  defp props_for(_field, _form_state), do: @input_disabled

  defp radio_props_for(_field, :new_mode), do: @radio_enabled
  defp radio_props_for(_field, _form_state), do: @radio_disabled
end
