defmodule Sig.Repo.Migrations.CreateEmployeeCompanyAssignmentsTable do
  use Ecto.Migration

  def up do
    create table(:employee_company_assignments) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        null: false

      add :assigned_company_id, references(:entities, with: [org_id: :org_id]), null: false
      add :start_date, :date, null: false

      timestamps()
    end

    create unique_index(
             :employee_company_assignments,
             [:start_date, :assigned_company_id, :registration_id, :org_id],
             name: :employee_company_assignments_company_start_date
           )

    execute("""
      CREATE TRIGGER ensure_at_least_one_employee_company_assignment_for_registration_on_delete
      AFTER DELETE ON employee_company_assignments
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_at_least_one_resource_for_registration ();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER ensure_at_least_one_employee_company_assignment_for_registration_on_delete
      ON employee_company_assignments;
    """)

    drop index(:employee_company_assignments, [
           :start_date,
           :assigned_company_id,
           :registration_id,
           :org_id
         ])

    drop table(:employee_company_assignments)
  end
end
