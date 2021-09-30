defmodule Sig.Repo.Migrations.OrgSectorsTable do
  use Ecto.Migration

  def change do
    create table(:org_sectors) do
      add :org_id, references(:orgs), primary_key: true

      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:org_sectors, [:name, :org_id])
  end
end
