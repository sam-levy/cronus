defmodule Sig.Repo.Migrations.CreateIndividualsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:gender, [:male, :female, :other])

    create table(:individuals, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true
      add :entity_id, references(:entities, with: [org_id: :org_id]), primary_key: true

      add :name, :string, null: false
      add :cpf, :string, size: 11, null: false
      add :gender, :gender, null: false

      timestamps()
    end

    create unique_index(:individuals, [:cpf, :org_id])
  end
end
