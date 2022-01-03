defmodule Sig.Finance.FinancialTransactions.FinancialTransaction do
  use Sig.Schema

  alias Sig.Organizations.Org

  defenum(FinancialTransactionType, :financial_transaction_type, [:bank, :cash])

  schema "financial_transactions" do
    belongs_to :org, Org, primary_key: true

    field :type, FinancialTransactionType
  end
end
