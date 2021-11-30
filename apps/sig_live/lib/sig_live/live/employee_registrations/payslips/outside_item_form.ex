defmodule SigLive.EmployeeRegistrations.Payslips.OutsideItemForm do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Finance

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

  @form_states [:new_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop payslip, :struct, required: true

  data changeset, :struct, default: HR.create_payslip_outside_item_change()
  data message, :string, default: nil

  @impl true
  def handle_event("save", %{"item" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def handle_event("form_change", %{"item" => params}, socket) do
    {:noreply, assign(socket, changeset: HR.create_payslip_outside_item_change(params))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Adicionar Item Fora do Holerite" close={@close_event}>
      <Form for={@changeset} change="form_change" submit="save" opts={autocomplete: "off"}>
        <Field name={:description} class="form-field">
          <Label class="form-label">Descrição</Label>
          <TextInput class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:entry_type} class="form-field flex space-x-3">
          <label class="form-side-label">
            <RadioButton class="mr-1" value="credit" checked /> Crédito
          </label>

          <label class="form-side-label">
            <RadioButton class="mr-1" value="debit" /> Débito
          </label>
        </Field>

        <Field name={:amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput value={format_amount(@changeset)} class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field :if={show?(@changeset)} name={:is_payment_advance} class="form-field">
          <div class="flex items-center">
            <Checkbox class="form-checkbox"/>
            <Label class="form-side-label">É Adiantamento de Salário</Label>
          </div>

          <ErrorTag class="form-error-tag block"/>
        </Field>

        <div :if={@message} class="form-error-tag">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp validate_params(context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("payslip_id", "payslip_id")
      |> HR.create_payslip_outside_item_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{payslip: payslip} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip_outside_item(payslip, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}, socket: socket}) when is_struct(changeset) do
    {:noreply, assign(socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _item}, socket: socket}) do
    %{payslip: payslip, close_fun: close_fun} = socket.assigns

    HR.broadcast_updated_payslip(payslip, nil, refetch: true, preload_registration: true)
    HR.broadcast_payslip_items(payslip)
    Finance.broadcast_payables_for_payslip(payslip)

    send(self(), {:flash, :info, "Item adicionado"})
    close_fun.()

    {:noreply, socket}
  end

  defp show?(%{changes: %{entry_type: :debit}}), do: true
  defp show?(_), do: false
end
