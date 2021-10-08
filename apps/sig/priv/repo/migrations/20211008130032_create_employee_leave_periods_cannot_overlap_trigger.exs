defmodule Sig.Repo.Migrations.CreateEmployeeLeavePeriodsCannotOverlapTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION employee_leave_periods_cannot_overlap ()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
      AS
    $$
    DECLARE
      previous_end_date date;
      next_start_date date;
    BEGIN
      SELECT
        MAX (end_date)
      FROM
        employee_leave_periods
      WHERE
        id != NEW.id AND
        org_id = NEW.org_id AND
        registration_id = NEW.registration_id AND
        start_date <= NEW.start_date
      INTO previous_end_date;

      SELECT
        MIN (start_date)
      FROM
        employee_leave_periods
      WHERE
        id != NEW.id AND
        org_id = NEW.org_id AND
        registration_id = NEW.registration_id AND
        start_date > NEW.start_date
      INTO next_start_date;

      IF
        previous_end_date >= NEW.start_date
      THEN
        RAISE 'start_date before or equal to an existing record end_date'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      IF
        next_start_date <= NEW.end_date
      THEN
        RAISE 'end_date after or equal to an existing record start_date'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      RETURN NEW;
    END;
    $$
    """)

    execute("""
    CREATE TRIGGER employee_leave_periods_cannot_overlap
      BEFORE INSERT OR UPDATE ON employee_leave_periods
      FOR EACH ROW
      EXECUTE PROCEDURE employee_leave_periods_cannot_overlap ();
    """)
  end

  def down do
    execute("DROP TRIGGER employee_leave_periods_cannot_overlap ON employee_leave_periods;")
    execute("DROP FUNCTION employee_leave_periods_cannot_overlap;")
  end
end
