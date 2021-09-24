defmodule Sig.Repo.Migrations.CreateEntitiesTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:entity_type, [:physical, :legal])

    create table(:entities) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :entity_type, null: false

      timestamps()
    end
  end
end
