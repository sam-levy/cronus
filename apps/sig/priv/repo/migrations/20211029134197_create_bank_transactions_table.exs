defmodule Sig.Repo.Migrations.CreateBankTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:bank_transactions, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true

      add :financial_transaction_id, references(:financial_transactions, with: [org_id: :org_id]),
        primary_key: true

      add :bank_account_id, references(:bank_accounts, with: [org_id: :org_id]), primary_key: true
    end

    create unique_index(
             :bank_transactions,
             [:financial_transaction_id, :org_id],
             name: :bank_transactions_financial_transaction_unique
           )
  end
end
