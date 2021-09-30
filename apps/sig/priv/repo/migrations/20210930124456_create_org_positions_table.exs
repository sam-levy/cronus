defmodule Sig.Repo.Migrations.CreateOrgPositionsTable do
  use Ecto.Migration

  def change do
    create table(:org_positions) do
      add :org_id, references(:orgs), primary_key: true

      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:org_positions, [:name, :org_id])
  end
end
