defmodule Sig.Repo.Migrations.CreateEmployeeLeavePeriodsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def up do
    create_type(:employee_leave_period_type, [:maternity_leave, :medical_license])

    create table(:employee_leave_periods) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :type, :employee_leave_period_type, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false

      timestamps()
    end

    create constraint(
             :employee_leave_periods,
             :employee_leave_periods_start_date_before_end_date,
             check: "start_date < end_date"
           )

    execute("""
    CREATE TRIGGER employee_leave_periods_cannot_overlap
      BEFORE INSERT OR UPDATE ON employee_leave_periods
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_no_period_overlap_with_registration ();
    """)
  end

  def down do
    execute("DROP TRIGGER employee_leave_periods_cannot_overlap ON employee_leave_periods;")

    drop constraint(:employee_leave_periods, :employee_leave_periods_start_date_before_end_date)

    drop table(:employee_leave_period_type)

    drop_type(:employee_leave_period_type)
  end
end
