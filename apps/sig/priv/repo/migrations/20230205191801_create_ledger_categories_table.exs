defmodule Sig.Repo.Migrations.CreateLedgerCategoriesTable do
  use Ecto.Migration

  def change do
    create table(:ledger_categories) do
      add :org_id, references(:orgs), primary_key: true

      add :code, :string, null: false
      add :description, :citext, null: false
      add :entry_type, :entry_type, null: false

      add :chart_of_account_id, references(:chart_of_accounts, with: [org_id: :org_id]),
        null: false

      timestamps()
    end

    create unique_index(:ledger_categories, [:code, :chart_of_account_id, :org_id],
             name: :ledger_categories_code_chart_of_account_id_unique
           )

    create unique_index(:ledger_categories, [:description, :chart_of_account_id, :org_id],
             name: :ledger_categories_description_chart_of_account_id_unique
           )
  end
end
