defmodule Sig.Repo.Migrations.CreateOrgPositionsTable do
  use Ecto.Migration

  def change do
    create table(:org_positions, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true
      add :name, :citext, primary_key: true

      timestamps()
    end
  end
end
