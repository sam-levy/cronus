defmodule Sig.Repo.Migrations.CreateFinancialTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:financial_transactions) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :financial_transaction_type, null: false
      add :placement_date, :date, null: false
      add :clearing_date, :date
      add :amount, :integer, null: false
      add :entry_type, :entry_type, null: false
      add :description, :string, null: false

      add :transfer_counterparty_id, references(:financial_transactions, with: [org_id: :org_id])

      timestamps()
    end

    create constraint(
             :financial_transactions,
             :financial_transactions_amount_positive,
             check: "amount >= 0"
           )
  end
end
