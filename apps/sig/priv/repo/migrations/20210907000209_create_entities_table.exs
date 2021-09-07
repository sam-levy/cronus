defmodule Sig.Repo.Migrations.CreateEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :organization_id, references(:organizations)

      timestamps()
    end
  end
end
