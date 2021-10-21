defmodule Sig.Repo.Migrations.CreateEmployeeSuspensionsTable do
  use Ecto.Migration

  def up do
    create table(:employee_suspensions) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :description, :string, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false

      timestamps()
    end

    create constraint(
             :employee_suspensions,
             :employee_suspensions_start_date_before_or_equal_end_date,
             check: "start_date <= end_date"
           )

    execute("""
      CREATE TRIGGER employee_suspensions_cannot_overlap
      BEFORE INSERT OR UPDATE ON employee_suspensions
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_no_period_overlap_with_registration ();
    """)
  end

  def down do
    execute("DROP TRIGGER employee_suspensions_cannot_overlap ON employee_suspensions;")

    drop constraint(
           :employee_suspensions,
           :employee_suspensions_start_date_before_or_equal_end_date
         )

    drop table(:employee_suspensions)
  end
end
