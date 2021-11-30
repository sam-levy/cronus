defmodule Sig.Repo.Migrations.CreatePayslipsValidateValidateNoPeriodOverlapProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION validate_payslips_no_period_overlap ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      DECLARE
        previous_end_date date;
        next_start_date date;
      BEGIN
        SELECT MAX (end_date)
        FROM payslips
        WHERE
          id != NEW.id AND
          org_id = NEW.org_id AND
          registration_id = NEW.registration_id AND
          type = NEW.type AND
          start_date <= NEW.start_date
        INTO previous_end_date;

        SELECT MIN (start_date)
        FROM payslips
        WHERE
          id != NEW.id AND
          org_id = NEW.org_id AND
          registration_id = NEW.registration_id AND
          type = NEW.type AND
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
      CREATE TRIGGER validate_payslips_no_period_overlap
      BEFORE INSERT OR UPDATE ON payslips
      FOR EACH ROW
      EXECUTE PROCEDURE validate_payslips_no_period_overlap ();
    """)
  end

  def down do
    execute("DROP TRIGGER validate_payslips_no_period_overlap ON payslips;")
  end
end
