defmodule Sig.Repo.Migrations.CreateEmployeeCompanyAssignmentsTable do
  use Ecto.Migration

  def change do
    create table(:employee_company_assignments) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]), null: false
      add :company_id, references(:entities, with: [org_id: :org_id]), null: false
      add :start_date, :date, null: false

      timestamps()
    end

    create unique_index(
             :employee_company_assignments,
             [:start_date, :company_id, :registration_id, :org_id],
             name: :employee_company_assignments_company_start_date
           )
  end
end
