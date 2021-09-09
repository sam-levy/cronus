defmodule Sig.Repo.Migrations.CreateIndividualsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:gender, [:male, :female, :other])

    create table(:individuals, primary_key: false) do
      add :entity_id, references(:entities), primary_key: true

      add :name, :string, null: false
      add :cpf, :string, size: 11, null: false
      add :gender, :gender, null: false

      add :organization_id, references(:organizations), null: false

      timestamps()
    end

    create unique_index(:individuals, [:cpf, :organization_id])
  end
end
