defmodule SigLive.AccountsPayable.FinancialTransactionsList do
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts

  prop org, :struct, required: true
  prop financial_transactions, :list, required: true

  data financial_transaction_id, :string, default: nil
  data confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"financial_transaction_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, financial_transaction_id: id)}
  end

  @impl true
  def handle_event("delete_financial_transaction", _, socket) do
    %{
      financial_transactions: financial_transactions,
      financial_transaction_id: id
    } = socket.assigns

    with {:ok, financial_transaction} <- fetch_financial_transaction(financial_transactions, id),
         {:ok, financial_transaction} <- Finance.delete_financial_transaction(financial_transaction) do
      Finance.broadcast_deleted_financial_transaction(financial_transaction)
      flash_info("Transação removida")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_financial_transaction(financial_transactions, id) do
    case Enum.find(financial_transactions, &(&1.id == id)) do
      nil -> {:error, "Transação não encontrado"}
      financial_transaction -> {:ok, financial_transaction}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_financial_transaction"
        dialog_title="Confirmar Remoção da transação financeira"
        confirmation_msg="Deseja realmente remover esta transação financeira? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg my-5">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Transações
                </span>
              </div>
            </th>
          </tr>

          <tr
            :if={@financial_transactions != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Liquidação</th>
            <th class="px-3 text-left">Descrição</th>
            <th class="px-3 text-left">Vencimento</th>
            <th class="px-3 text-left">Forma</th>
            <th class="px-3 text-right">Valor</th>
            <th class="text-left"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for transaction <- @financial_transactions}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="pl-6 text-left">
                {#if transaction.clearing_date == nil}
                  <span class="label-yellow mr-1">
                    liq pendente
                  </span>

                  <span class="italic text-gray-500">
                    Pgto. {format_date(transaction.placement_date)}
                  </span>
                {#else}
                  {format_date(transaction.clearing_date)}
                {/if}
              </td>

              <td class="py-3 px-3 text-left">
                {transaction.description}
              </td>

              <td class="py-3 px-3 text-left">
              </td>

              <td class="px-3 text-left">
                {capitalize_type(transaction.type)}
              </td>

              <td class="px-3 text-right">

                {transaction.amount}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-financial_transaction_id={transaction.id}
                    class="dropdown-item not-italic"
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
      message: nil,
      financial_transaction_id: nil,
      confirmation_dialog_state: :closed
    ]
  end
end
