defmodule Sig.Repo.Migrations.CreatePayslipsValidatePayslipGroupProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION validate_payslip_payslip_group ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      DECLARE
        payslip_group record;
      BEGIN
        SELECT type, date
        FROM payslip_groups
        WHERE
          id = NEW.group_id AND
          org_id = NEW.org_id
        INTO payslip_group;

        IF
          payslip_group.type != NEW.type
        THEN
          RAISE 'payslip and payslip group must have the same type'
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        IF
          extract (month from payslip_group.date) != extract (month from NEW.start_date) OR
          extract (year from payslip_group.date) != extract (year from NEW.start_date)
        THEN
          RAISE 'payslip start_date and payslip group date must belong to the same month and year'
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        RETURN NEW;
      END;
      $$
    """)

    execute("""
      CREATE TRIGGER validate_payslip_payslip_group
      BEFORE INSERT OR UPDATE ON payslips
      FOR EACH ROW
      EXECUTE PROCEDURE validate_payslip_payslip_group ();
    """)
  end

  def down do
    execute("DROP TRIGGER validate_payslip_payslip_group ON payslips;")
  end
end
