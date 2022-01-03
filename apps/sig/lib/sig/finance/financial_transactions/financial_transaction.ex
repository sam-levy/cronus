defmodule Sig.Finance.FinancialTransactions.FinancialTransaction do
  use Sig.Schema

  alias Sig.Organizations.Org

  defenum(FinancialTransactionType, :financial_transaction_type, [:bank, :cash])

  schema "financial_transactions" do
    belongs_to :org, Org, primary_key: true

    field :type, FinancialTransactionType
    field :placement_date, :date
    field :clearing_date, :date
    field :amount, Money.Ecto.Amount.Type
    field :entry_type, Sig.EntryType
    field :description, :string
    field :is_internal_transfer, :boolean

    belongs_to :counterparty, __MODULE__

    timestamps()
  end
end
