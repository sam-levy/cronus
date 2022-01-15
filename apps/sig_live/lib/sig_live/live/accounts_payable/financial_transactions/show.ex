defmodule SigLive.AccountsPayable.FinancialTransactions.Show do
  use SigLive, :surface_live_component

  import Sig.Enums.FinancialTransaction, only: [is_bank_type: 1]

  alias Sig.Finance
  alias Sig.Repo

  alias SigLive.Components.Modal

  prop close_event, :event, required: true
  prop org, :struct, required: true
  prop financial_transaction, :string, required: true

  @impl true
  def update(assigns, socket) do
    %{financial_transaction: financial_transaction} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payables: Finance.list_payables_by(financial_transaction, preload: [:payslip, :employee]),
        financial_transaction: Repo.preload(financial_transaction, Finance.default_financial_transaction_preloads())
        )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Transação Financeira" close={@close_event}>
      <div class="space-y-4">
        <div>
          {#case @financial_transaction}
            {#match %{type: type, bank_account: %{name: name}} when is_bank_type(type)}
              <div class="text-md text-gray-700">{name}</div>

              <div class="text-sm text-gray-500 trucate">
                {format_bank_account(@financial_transaction.bank_account)}
              </div>

            {#match %{type: type} when is_bank_type(type)}
              <div class="text-md text-gray-700">Conta</div>

            {#match _}
              <div class="text-md text-gray-700">Dinheiro</div>
          {/case}
        </div>

        <div>
          <div class="text-md text-gray-700">
            Total {transaction_type(@financial_transaction)}
          </div>

          <div class="text-sm text-gray-500 trucate">
            {format_amount(@financial_transaction.amount)}
          </div>
        </div>

        <div>
          <div class="text-md text-gray-700">
            Pago por
          </div>

          <div class="text-sm text-gray-500 trucate">
            {@financial_transaction.created_by.email}
          </div>
        </div>

        <ul role="list" class="bg-gray-50 rounded-lg divide-y divide-gray-200">
          {#for payable <- @payables}
            <a
              class="py-3 px-4 block hover:bg-gray-100 hover:rounded-lg"
              href={Routes.sig_employee_registrations_show_path(@socket, :payslip, @org, payable.payslip.registration_id, payable.payslip)}
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
    </Modal>
    """
  end

  defp transaction_type(%{entry_type: :debit}), do: "Débito"
  defp transaction_type(_), do: "Crédito"
end
