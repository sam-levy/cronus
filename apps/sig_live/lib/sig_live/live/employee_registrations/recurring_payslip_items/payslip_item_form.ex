defmodule SigLive.EmployeeRegistrations.RecurringPayslipItems.PayslipItemForm do
  use SigLive, :surface_live_component

  alias Sig.HR

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
  prop org, :struct, required: true
  prop registration, :struct, required: true

  data changeset, :struct, default: HR.create_recurring_payslip_item_change(:payslip_item)

  @impl true
  def handle_event("save", %{"recurring_payslip_item" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Adicionar Item Recorrente do Holerite" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:payslip_category_id} class="form-field">
          <Label class="form-label">Categoria</Label>
          <Select
            prompt=""
            options={payslip_categories_for_select(@org)}
            class="form-input"
          />
          <ErrorTag class="form-error-tag"/>
        </Field>

        <Field name={:item_amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput value={format_amount(@changeset)} class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

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
      |> Map.put("registration_id", "registration_id")
      |> HR.create_recurring_payslip_item_change(:payslip_item)

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{registration: registration} = context.socket.assigns

    Map.put(
      context,
      :return,
      HR.create_recurring_payslip_item(registration, changeset.changes, :payslip_item)
    )
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, _item}, socket: socket}) do
    %{registration: registration, close_fun: close_fun} = socket.assigns

    HR.broadcast_registration_recurring_payslip_items(registration)
    send(self(), {:flash, :info, "Item adicionado"})
    close_fun.()

    {:noreply, socket}
  end

  defp payslip_categories_for_select(org) do
    org
    |> HR.list_payslip_categories()
    |> Map.new(fn category ->
      entry_type = if category.entry_type == :credit, do: "Crédito", else: "Débito"

      {"#{category.code} - #{category.description} - #{entry_type}", category.id}
    end)
  end
end
