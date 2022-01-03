defmodule Sig.Factories.BankTransactionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction

      def factory(:bank_transaction, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %BankTransaction{
          org: org,
          financial_transaction: build(:financial_transaction, org: org),
          bank_account: build(:bank_account, org: org)
        }
      end
    end
  end
end
