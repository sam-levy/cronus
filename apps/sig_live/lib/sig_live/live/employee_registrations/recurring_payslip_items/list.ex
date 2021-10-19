defmodule SigLive.EmployeeRegistrations.RecurringPayslipItems.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.PayslipItemForm
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.PayslipItemModelForm
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.OutsideItemForm

  prop registration, :struct, required: true
  prop recurring_payslip_items, :list, required: true

  data delete_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()
  data payslip_item_form_state, :atom, default: :closed, values!: PayslipItemForm.states()
  data payslip_item_model_form_state, :atom, default: :closed, values!: PayslipItemModelForm.states()
  data outside_item_form_state, :atom, default: :closed, values!: OutsideItemForm.states()

  data item_id, :string, default: nil

  @impl true
  def handle_event("open_new_payslip_item_form", _, socket) do
    {:noreply, assign(socket, payslip_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_new_payslip_item_model_form", _, socket) do
    {:noreply, assign(socket, payslip_item_model_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_new_outside_item_form", _, socket) do
    {:noreply, assign(socket, outside_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_payslip_item_delete_confirmation_dialog", %{"item-id" => id}, socket) do
    {:noreply, assign(socket, delete_confirmation_dialog_state: :open, item_id: id)}
  end

  @impl true
  def handle_event("delete_recurrent_payslip_item", _, socket) do
    %{registration: registration, item_id: item_id} = socket.assigns

    case HR.delete_recurring_payslip_item(registration, item_id) do
      {:ok, _item} ->
        HR.broadcast_registration_recurring_payslip_items(registration)
        send(self(), {:flash, :info, "Item removido"})

        {:noreply, assign(socket, closed_state())}

      :error ->
        send(self(), {:flash, :info, "Falha ao remover o item"})

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_recurrent_payslip_item"
        dialog_title="Confirmar Remoção"
        confirmation_msg="Deseja realmente remover o item?"
        action_btn_msg="Remover"
      />

      <PayslipItemForm
        :if={@payslip_item_form_state != :closed}
        id="payslip_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <PayslipItemModelForm
        :if={@payslip_item_model_form_state != :closed}
        id="payslip_item_model_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <OutsideItemForm
        :if={@outside_item_form_state != :closed}
        id="outside_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="sticky top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Itens Recorrentes do Holerite
                </span>

                <DropdownBtn>
                  <a :on-click="open_new_payslip_item_form" class="dropdown-item">Item do holerite</a>
                  <a :on-click="open_new_payslip_item_model_form" class="dropdown-item">Item a partir de modelo</a>
                  <a :on-click="open_new_outside_item_form" class="dropdown-item">Item fora do holerite</a>
                </DropdownBtn>
              </div>
            </th>
          </tr>

          <tr
            :if={@recurring_payslip_items != []}
            class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Código</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Vencimentos</th>
            <th class="py-3 px-6 text-right">Descontos</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for item <- @recurring_payslip_items}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                {item.code}
              </td>

              <td class="py-3 px-6 text-left">
                {item.description}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :credit, do: item.amount}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :debit, do: item.amount}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_payslip_item_delete_confirmation_dialog"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      item_id: nil,
      payslip_item_form_state: :closed,
      payslip_item_model_form_state: :closed,
      outside_item_form_state: :closed,
      delete_confirmation_dialog_state: :closed
    ]
  end
end
