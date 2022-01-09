defmodule Sig.Factories.FinancialTransactionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.FinancialTransactions.FinancialTransaction
      alias Sig.Enums.FinancialTransaction.Type, as: FinancialTransactionType

      def factory(:financial_transaction, attrs) do
        placement_date = Keyword.get(attrs, :placement_date) || Date.utc_today()

        %FinancialTransaction{
          org: build(:org),
          type: random_enum_value(:financial_transaction_type),
          placement_date: placement_date,
          clearing_date: placement_date,
          amount: Enum.random(100_00..5_000_00) |> Money.new(),
          entry_type: random_enum_value(:entry_type),
          description: Faker.Lorem.sentence()
        }
      end

      def random_enum_value(:financial_transaction_type) do
        random_enum_value(FinancialTransactionType)
      end
    end
  end
end
