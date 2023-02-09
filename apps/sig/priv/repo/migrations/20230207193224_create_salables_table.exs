defmodule Sig.Repo.Migrations.CreateSalablesTable do
  use Ecto.Migration

  import EctoEnumMigration

  def change do
    create_type(:salable_type, [:good, :service])

    create table(:salables) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :salable_type, null: false
      add :code, :citext, null: false
      add :description, :citext, null: false
      add :unit, :citext, null: false

      add :entity_id, references(:entities, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(:salables, [:code, :entity_id, :org_id],
             name: :salables_code_entity_id_org_id_unique
           )

    create unique_index(:salables, [:description, :entity_id, :org_id],
             name: :salables_description_entity_id_org_id_unique
           )
  end
end
