defmodule SigLive.PayslipCategories.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    RadioButton,
    Checkbox,
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop payslip_category_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, payslip_category_id: payslip_category_id} = assigns

    payslip_category = get_payslip_category(org, payslip_category_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payslip_category: payslip_category,
        changeset: set_changeset(payslip_category)
      )

    {:ok, socket}
  end

  def handle_event("form_change", %{"category" => params}, socket) do
    %{form_state: form_state, payslip_category: payslip_category} = socket.assigns

    case form_state do
      :new_mode ->
        {:noreply, assign(socket, changeset: HR.create_payslip_category_change(params))}

      :edit_mode ->
        {:noreply,
         assign(socket, changeset: HR.update_payslip_category_change(payslip_category, params))}
    end
  end

  @impl true
  def handle_event("save", %{"category" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} submit="save" change="form_change" opts={autocomplete: "off"}>
        <Field name={:code} class="form-field">
          <Label class="form-label">Código</Label>
          <TextInput class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:description} class="form-field">
          <Label class="form-label">Descrição</Label>
          <TextInput class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:entry_type} class="form-field flex gap-5">
          <label class="form-side-label">
            <RadioButton class="form-radio" value="credit" checked /> Crédito
          </label>

          <label class="form-side-label">
            <RadioButton class="form-radio" value="debit" /> Débito
          </label>
        </Field>

        <Field :if={show?(@changeset)} name={:is_payment_advance} class="form-field mt-3">
          <div class="flex items-center">
            <Checkbox class="form-checkbox"/>
            <Label class="form-side-label">É Adiantamento de Salário</Label>
          </div>

          <ErrorTag class="form-error-tag block"/>
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_payslip_category(_org, nil), do: nil
  defp get_payslip_category(org, payslip_category_id), do: HR.get_payslip_category(org, payslip_category_id)

  defp set_changeset(nil), do: HR.create_payslip_category_change(%{entry_type: :credit})
  defp set_changeset(payslip_category), do: HR.update_payslip_category_change(payslip_category)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> HR.create_payslip_category_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{payslip_category: payslip_category} = context.socket.assigns

    changeset = HR.update_payslip_category_change(payslip_category, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip_category(org, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{payslip_category: payslip_category} = context.socket.assigns

    Map.put(context, :return, HR.update_payslip_category(payslip_category, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, payslip_category}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, payslip_category)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, payslip_category) do
    HR.broadcast_new_payslip_category(payslip_category)
  end

  defp handle_broadcast(:edit_mode, payslip_category) do
    HR.broadcast_updated_payslip_category(payslip_category)
  end

  defp handle_flash(:new_mode), do: send(self(), {:flash, :info, "Categoria de Item de Holerite criada"})
  defp handle_flash(:edit_mode), do: send(self(), {:flash, :info, "Categoria de Item de Holerite alterada"})

  defp handle_title(:new_mode), do: "Novo Categoria de Item de Holerite"
  defp handle_title(:edit_mode), do: "Renomear Categoria de Item de Holerite"

  defp show?(%{changes: %{entry_type: :credit}}), do: false
  defp show?(%{changes: %{entry_type: :debit}}), do: true
  defp show?(%{data: %{entry_type: :debit}}), do: true
  defp show?(_), do: false
end
