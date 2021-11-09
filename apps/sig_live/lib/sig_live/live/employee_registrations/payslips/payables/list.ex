defmodule SigLive.EmployeeRegistrations.Payslips.Payables.List do
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Payslips.Payables.Form

  prop registration, :struct, required: true
  prop payslip, :struct, required: true
  prop entity, :struct, required: true
  prop payables, :list, default: []

  data delete_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()
  data form_state, :atom, default: :closed, values!: Form.states()

  data message, :string, default: nil

  @impl true
  def update(%{payables: _payables} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_difference()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("open_new_payable_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode, payable_id: nil)}
  end

  @impl true
  def handle_event("open_show_payable_form", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, payable_id: id)}
  end

  @impl true
  def handle_event("open_edit_payable_form", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, payable_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, delete_confirmation_dialog_state: :open, payable_id: id)}
  end

  @impl true
  def handle_event("set_as_auto_adjustable_amount", %{"payable_id" => id}, socket) do
    %{payslip: payslip} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         {:ok, _payable} <- Finance.set_payable_for_payslip_as_auto_adjustable(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)

      {:noreply, socket}
    else
      {:error, message} -> send(self(), {:flash, :error, message})
    end
  end

  @impl true
  def handle_event("unset_as_auto_adjustable_amount", %{"payable_id" => id}, socket) do
    %{payslip: payslip} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         :ok <- Finance.unset_payable_for_payslip_as_auto_adjustable(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)

      {:noreply, socket}
    else
      {:error, message} -> send(self(), {:flash, :error, message})
    end
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("delete_payable", _, socket) do
    %{payslip: payslip, payable_id: payable_id} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, payable_id),
         {:ok, _payable} <- Finance.delete_payable_for_payslip(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)
      send(self(), {:flash, :info, "Pagamento removido"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} -> {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def render(%{payslip: nil} = assigns) do
    ~F"""
    <div></div>
    """
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payable"
        dialog_title="Confirmar Remoção"
        confirmation_msg="Deseja realmente remover o pagamento?"
        action_btn_msg="Remover"
        error_message={@message}
      />

      <Form
        :if={@form_state != :closed}
        id="payable_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@entity}
        {=@registration}
        {=@payslip}
        {=@payable_id}
      />

      <table class="w-full bg-white shadow-lg mb-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider mr-4">
                  Pagamentos
                </span>

                <ButtonPlus on_click="open_new_payable_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@payables != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Vencimento</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-left"></th>
            <th class="py-3 px-6 text-right">Valor</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for payable <- @payables}
            <tr class="border-b hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                <a
                  :on-click="open_show_payable_form"
                  phx-value-payable_id={payable.id}
                  class="cursor-pointer hover:underline"
                >
                  {format_date(payable.due_date)}
                </a>
              </td>

              <td class="py-3 px-6 text-left">
                {payable.description}
              </td>

              <td class="py-3 px-6 text-right">
                {#if !payable.is_fulfilled and payable.payslip_payable.is_auto_adjustable_amount}
                  <span class="label-green">valor automático</span>
                {/if}
              </td>

              <td class="py-3 px-6 text-right">
                {format_amount(payable.amount)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_payable_form"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :if={!payable.is_fulfilled and !payable.payslip_payable.is_auto_adjustable_amount}
                    :on-click="set_as_auto_adjustable_amount"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Atribuir valor automático
                  </a>

                  <a
                    :if={!payable.is_fulfilled and payable.payslip_payable.is_auto_adjustable_amount}
                    :on-click="unset_as_auto_adjustable_amount"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Remover valor automático
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr
            :if={@payables != [] and @difference != Money.new(0)}
            class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider"
          >
            <td class="py-2 px-6 text-left" colspan="3">Diferença</td>
            <td class="py-2 px-6 text-right">{format_amount(@difference)}</td>
            <td></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp assign_difference(%{assigns: %{payslip: nil}} = socket), do: socket

  defp assign_difference(socket) do
    %{assigns: %{payslip: payslip, payables: payables}} = socket
    payables_amount_sum = Enum.reduce(payables, Money.new(0), & Money.add(&2, &1.amount))

    assign(socket, difference: Money.subtract(payslip.amount, payables_amount_sum))
  end

  defp close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      payable_id: nil,
      message: nil,
      form_state: :closed,
      delete_confirmation_dialog_state: :closed
    ]
  end
end
