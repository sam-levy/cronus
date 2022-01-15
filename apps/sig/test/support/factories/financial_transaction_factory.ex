defmodule Sig.Factories.FinancialTransactionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.FinancialTransactions.FinancialTransaction
      alias Sig.Enums.FinancialTransaction.Type, as: FinancialTransactionType

      def factory(:financial_transaction, attrs) do
        clearing_date = Keyword.get(attrs, :clearing_date) || Date.utc_today()
        placement_date = Keyword.get(attrs, :placement_date) || clearing_date

        org = Keyword.get(attrs, :org) || insert(:org)
        created_by = Keyword.get(attrs, :created_by) || insert(:user, org: org)

        %FinancialTransaction{
          org: org,
          type: random_enum_value(:financial_transaction_type),
          placement_date: placement_date,
          clearing_date: clearing_date,
          amount: Enum.random(100_00..5_000_00) |> Money.new(),
          entry_type: random_enum_value(:entry_type),
          description: Faker.Lorem.sentence(),
          created_by: created_by
        }
      end

      def random_enum_value(:financial_transaction_type) do
        random_enum_value(FinancialTransactionType)
      end
    end
  end
end
