defmodule Sig.Repo.Migrations.CreateChartOfAccountsTablee do
  use Ecto.Migration

  def change do
    create table(:chart_of_accounts) do
      add :org_id, references(:orgs), primary_key: true

      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:chart_of_accounts, [:name, :org_id])
  end
end
