defmodule Sig.Repo.Migrations.CreateEmployeeSalariesTable do
  use Ecto.Migration

  def change do
    create table(:employee_salaries) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :start_date, :date, null: false
      add :amount, :integer, null: false

      timestamps()
    end
  end
end
