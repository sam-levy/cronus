defmodule Sig.Repo.Migrations.CreateEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :organization_id, references(:organizations), primary_key: true

      timestamps()
    end
  end
end
