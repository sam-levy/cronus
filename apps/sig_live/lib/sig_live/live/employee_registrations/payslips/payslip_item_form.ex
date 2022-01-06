defmodule SigLive.EmployeeRegistrations.Payslips.PayslipItemForm do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Finance

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    Select,
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

  data changeset, :struct, default: HR.create_payslip_item_change()
  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:categories, HR.list_payslip_categories(assigns.payslip.org_id))

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"item" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Adicionar Item do Holerite" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:category_id} class="form-field">
          <Label class="form-label">Categoria</Label>
          <Select
            prompt=""
            options={payslip_categories_for_select(@categories)}
            class="form-input"
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

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

  defp validate_params(context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Map.put("payslip_id", "payslip_id")
      |> Map.put("code", "code")
      |> Map.put("entry_type", "credit")
      |> Map.put("description", "description")
      |> HR.create_payslip_item_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{payslip: payslip} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip_item(payslip, changeset.changes))
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
    Finance.broadcast_updated_payables(payslip)

    send(self(), {:flash, :info, "Item adicionado"})
    close_fun.()

    {:noreply, socket}
  end
end
