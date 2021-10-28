defmodule SigLive.EmployeeRegistrations.Payslips.UpdateItemAmountForm do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:open, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop payslip, :struct, required: true
  prop item_id, :string, required: true

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{payslip: payslip, item_id: item_id} = assigns
    item = HR.get_payslip_item(payslip, item_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        item: item,
        changeset: set_changeset(item)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"item" => params}, socket) do
    %{payslip: payslip, item: item} = socket.assigns

    %{payslip: payslip, item: item, params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Alterar Valor" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput value={format_amount(@changeset)} class="form-input"/>
          <ErrorTag class="form-error-tag"/>
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

  defp set_changeset(nil), do: nil
  defp set_changeset(item), do: HR.update_payslip_item_amount_change(item)

  defp validate_params(context) do
    %{item: item, params: params} = context
    changeset = HR.update_payslip_item_amount_change(item, params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{payslip: payslip, item: item} = context.socket.assigns

    Map.put(context, :return, HR.update_payslip_item_amount(payslip, item, changeset.changes))
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

    HR.broadcast_payslip_items(payslip)
    send(self(), {:flash, :info, "Item adicionado"})
    close_fun.()

    {:noreply, socket}
  end
end
