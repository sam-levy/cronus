defmodule Sig.Repo.Migrations.CreateCompaniesTable do
  use Ecto.Migration

  def change do
    create table(:companies, primary_key: false) do
      add :entity_id, references(:entities, with: [organization_id: :organization_id]),
        primary_key: true

      add :organization_id, references(:organizations), primary_key: true

      add :is_virtual, :boolean, null: false, default: false
      add :trade_name, :string, null: false
      add :registration_name, :string
      add :cnpj, :string, size: 14

      timestamps()
    end

    create unique_index(:companies, [:trade_name, :organization_id])
    create unique_index(:companies, [:registration_name, :organization_id])
    create unique_index(:companies, [:cnpj, :organization_id])

    create constraint(:companies, :companies_registration_name_and_cnpj_required_if_not_virtual,
             check: """
             CASE WHEN is_virtual = false THEN
               registration_name IS NOT NULL AND
               cnpj IS NOT NULL
             ELSE
               registration_name IS NULL AND
               cnpj IS NULL
             END
             """
           )
  end
end
