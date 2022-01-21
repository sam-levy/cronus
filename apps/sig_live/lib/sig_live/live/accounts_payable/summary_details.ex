defmodule SigLive.AccountsPayable.SummaryDetails do
  @moduledoc """
  This module is temporary and should be removed as soon as the bank account
  management feature is fully implemented.
  """
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias SigLive.Components.Modal

  prop org, :struct, required: true
  prop close_event, :event, required: true
  prop selected_financial_transaction_ids, :string, required: true

  @impl true
  def update(assigns, socket) do
    %{org: org, selected_financial_transaction_ids: ids} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(
        financial_transactions: Finance.list_financial_transactions_by(org, filter_by: [id: ids], preload: [:payables, :created_by])
        )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Transação Financeira" close={@close_event}>
      <div class="space-y-6 divide-y divide-gray-300">
        {#for transaction <- @financial_transactions}
          <div>
            <div class="my-3 px-3 text-md text-gray-700">
              {transaction.description}
            </div>

            <div class="mb-5 px-3 flex justify-between">
              <div>
                <div class="text-md text-gray-700">
                  Total {transaction_type(transaction)}
                </div>

                <div class="text-sm text-gray-500 trucate">
                  {format_amount(transaction.amount)}
                </div>
              </div>

              <div>
                <div class="text-md text-gray-700">
                  Pago por
                </div>

                <div class="text-sm text-gray-500 trucate">
                  {transaction.created_by.email}
                </div>
              </div>
            </div>

            <ul role="list" class="bg-gray-50 rounded-lg divide-y divide-gray-200">
              {#for payable <- transaction.payables}
                <a
                  class="py-3 px-4 block hover:bg-gray-100 hover:rounded-lg"
                  target="_blank"
                >
                  <div class="flex items-center space-x-4">
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-gray-900 truncate">
                        {#case payable}
                          {#match %{employee: %Ecto.Association.NotLoaded{}}}
                            {payable.description}
                          {#match _}
                            {payable.description} {payable.employee.name}
                        {/case}
                      </p>

                      <p class="text-sm text-gray-500 truncate">
                        {format_date(payable.due_date)}
                      </p>
                    </div>

                    <div class="inline-flex items-center text-base font-semibold text-gray-900">
                      {format_amount(payable.amount)}
                    </div>
                  </div>
                </a>
              {/for}
            </ul>
        </div>
        {/for}
      </div>
    </Modal>
    """
  end

  defp transaction_type(%{entry_type: :debit}), do: "Débito"
  defp transaction_type(_), do: "Crédito"
end
