defmodule Sig.Repo.Migrations.CreateEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :org_id, references(:orgs), primary_key: true

      timestamps()
    end
  end
end
