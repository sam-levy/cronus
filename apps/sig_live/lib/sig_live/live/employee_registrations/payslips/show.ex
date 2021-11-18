defmodule SigLive.EmployeeRegistrations.Payslips.Show do
  use SigLive, :surface_live_component

  alias Sig.HR
  alias Sig.Finance

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts
  alias SigLive.Components.ToggleIcon
  alias SigLive.EmployeeRegistrations.Payslips.OutsideItemForm
  alias SigLive.EmployeeRegistrations.Payslips.PayslipItemForm
  alias SigLive.EmployeeRegistrations.Payslips.UpdateItemAmountForm

  prop registration, :struct, required: true
  prop payslip, :struct, default: nil
  prop items, :list, default: []

  data payslip_item_form_state, :atom, default: :closed, values!: PayslipItemForm.states()
  data outside_item_form_state, :atom, default: :closed, values!: OutsideItemForm.states()
  data update_item_amount_form_state, :atom, default: :closed, values!: UpdateItemAmountForm.states()
  data delete_item_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()
  data delete_payslip_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()

  data item_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def update(%{items: items} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(
        payslip_items: Enum.filter(items, &(&1.type == :payslip_item)),
        outside_items: Enum.filter(items, &(&1.type == :outside_item))
      )
      |> assign_totals()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("open_new_payslip_item_form", _, socket) do
    {:noreply, assign(socket, payslip_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_new_outside_item_form", _, socket) do
    {:noreply, assign(socket, outside_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"item_id" => id}, socket) do
    {:noreply, assign(socket, delete_item_confirmation_dialog_state: :open, item_id: id)}
  end

  @impl true
  def handle_event("open_update_item_amount_form", %{"item_id" => id}, socket) do
    {:noreply, assign(socket, update_item_amount_form_state: :open, item_id: id)}
  end

  @impl true
  def handle_event("open_delete_payslip_confirmation_dialog", _, socket) do
    {:noreply, assign(socket, delete_payslip_confirmation_dialog_state: :open)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("toggle_close_payslip", _, socket) do
    %{payslip: payslip} = socket.assigns

    case HR.toggle_payslip_is_closed(payslip) do
      {:ok, payslip} ->
        HR.broadcast_payslip_update(payslip)

        message = if payslip.is_closed, do: "Holerite bloqueado", else: "Holerite desbloqueado"

        send(self(), {:flash, :info, message})

        {:noreply, socket}

      {:error, _changeset} ->
        send(self(), {:flash, :error, "Falha ao bloquear o holerite"})

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_payslip_item", _, socket) do
    %{payslip: payslip, item_id: item_id} = socket.assigns

    with {:ok, item} <- HR.fetch_payslip_item(payslip, item_id),
         {:ok, _item} <- HR.delete_payslip_item(payslip, item) do
      HR.broadcast_payslip_update(payslip)
      HR.broadcast_payslip_items(payslip)
      Finance.broadcast_payables_for_payslip(payslip)
      send(self(), {:flash, :info, "Item removido"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  @impl true
  def handle_event("delete_payslip", _, socket) do
    %{registration: registration, payslip: payslip} = socket.assigns

    case HR.delete_payslip(payslip) do
      {:ok, payslip} ->
        HR.broadcast_deleted_registration_payslip(registration, payslip)
        send(self(), {:flash, :info, "Holerite removido"})

        {:noreply, assign(socket, closed_state())}

      {:error, message} ->
        {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def render(%{payslip: nil} = assigns) do
    ~F"""
    <div class="text-gray-500 text-center">Ainda não possui holerites</div>
    """
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_item_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payslip_item"
        dialog_title="Confirmar Remoção do Item do Holerite"
        confirmation_msg="Deseja realmente remover o item?"
        action_btn_msg="Remover"
        error_message={@message}
      />

      <ConfirmationDialog
        :if={@delete_payslip_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payslip"
        dialog_title="Confirmar Remoção do Holerite"
        confirmation_msg="Deseja realmente remover o Holerite?"
        action_btn_msg="Remover"
        error_message={@message}
      />

      <PayslipItemForm
        :if={@payslip_item_form_state != :closed}
        id="payslip_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip}
      />

      <OutsideItemForm
        :if={@outside_item_form_state != :closed}
        id="outside_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip}
      />

      <UpdateItemAmountForm
        :if={@update_item_amount_form_state != :closed}
        id="update_item_amount_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip}
        {=@item_id}
      />

      <table class="w-full bg-white shadow-lg mb-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider mr-4">
                  Holerite {handle_date(@payslip)}
                  <span class="text-gray-400 italic font-extralight">
                    {capitalize_type(@payslip.type)}
                  </span>
                </span>

                <div class="flex items-center">
                  <ToggleIcon
                    is_active={!@payslip.is_closed}
                    toggle="toggle_close_payslip"
                    class="mr-3"
                    active_icon="lock_open"
                    inactive_icon="lock_closed"
                  />

                  <DropdownBtn disabled={@payslip.is_closed}>
                    <a :on-click="open_new_payslip_item_form" class="dropdown-item">Item do holerite</a>
                    <a :on-click="open_new_outside_item_form" class="dropdown-item">Item fora do holerite</a>
                    <a :if={@items == []} :on-click="open_delete_payslip_confirmation_dialog" class="dropdown-item">Remover Holerite</a>
                  </DropdownBtn>
                </div>
              </div>
            </th>
          </tr>

          <tr
            :if={@payslip_items != [] or @outside_items != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Código</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Vencimentos</th>
            <th class="py-3 px-6 text-right">Descontos</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for item <- @payslip_items}
            <tr class="border-b hover:bg-gray-50">
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
                <DropdownOpts :if={!@payslip.is_closed}>
                  <a
                    :on-click="open_update_item_amount_form"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Alterar Valor
                  </a>
                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr :if={@payslip_items != []} class="border-b italic bg-gray-100 text-sm text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="2">Subtotais</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip_items_credit_subtotal)}</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip_items_debit_subtotal)}</td>
            <td></td>
          </tr>

          <tr :if={@payslip_items != []} class="border-b text-sm bg-gray-100 font-medium text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="3">Líquido Holerite</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip_items_total)}</td>
            <td></td>
          </tr>

          {#for item <- @outside_items}
            <tr class="border-b hover:bg-gray-50">
              <td></td>

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
                    :on-click="open_update_item_amount_form"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Alterar Valor
                  </a>
                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr :if={@outside_items != []} class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="3">Total</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip.amount)}</td>
            <td></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp handle_date(%{start_date: start_date, end_date: end_date}) do
    if start_date == Date.beginning_of_month(start_date) and
         end_date == Date.end_of_month(end_date) do
      format_month(start_date)
    else
      format_date(start_date) <> " à " <> format_date(end_date)
    end
  end

  defp assign_totals(socket) do
    %{assigns: %{payslip_items: payslip_items}} = socket

    payslip_items_credit_subtotal = Sig.sum_by(:credit, payslip_items)
    payslip_items_debit_subtotal = Sig.sum_by(:debit, payslip_items)

    payslip_items_total =
      Money.subtract(payslip_items_credit_subtotal, payslip_items_debit_subtotal)

    assign(socket,
      payslip_items_credit_subtotal: payslip_items_credit_subtotal,
      payslip_items_debit_subtotal: payslip_items_debit_subtotal,
      payslip_items_total: payslip_items_total,
    )
  end

  defp close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      item_id: nil,
      message: nil,
      payslip_item_form_state: :closed,
      outside_item_form_state: :closed,
      update_item_amount_form_state: :closed,
      delete_item_confirmation_dialog_state: :closed,
      delete_payslip_confirmation_dialog_state: :closed
    ]
  end
end
