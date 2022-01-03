defmodule Sig.Repo.Migrations.CreateFinancialTransactionsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:financial_transaction_type, [:bank, :cash])

    create table(:financial_transactions) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :financial_transaction_type, null: false
    end
  end
end
