defmodule Sig.Repo.Migrations.CreateEmployeeWarningsTable do
  use Ecto.Migration

  def change do
    create table(:employee_warnings) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :date, :date, null: false
      add :description, :string, null: false

      timestamps()
    end
  end
end
