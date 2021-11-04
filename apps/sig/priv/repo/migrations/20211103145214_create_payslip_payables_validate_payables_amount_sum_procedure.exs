defmodule Sig.Repo.Migrations.CreatePayslipPayablesValidatePayablesAmountSumProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION payslip_payables_validate_payables_amount_sum_procedure ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      DECLARE
        payables_amount_sum integer;
        payslip_amount integer;
      BEGIN
        SELECT SUM (payables.amount)
        FROM payslip_payables
        LEFT JOIN
          payables
          ON payslip_payables.payable_id = payables.id
        WHERE
          payslip_payables.payslip_id = NEW.payslip_id AND
          payslip_payables.org_id = NEW.org_id
        INTO payables_amount_sum;

        SELECT amount
        FROM payslips
        WHERE
          id = NEW.payslip_id AND
          org_id = NEW.org_id
        INTO payslip_amount;

        IF
          payslip_amount - payables_amount_sum < 0
        THEN
          RAISE 'payables amount sum cannot exceed the payslip amount'
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        RETURN NEW;
      END;
      $$
    """)

    execute("""
      CREATE TRIGGER payslip_payables_validate_payables_amount_sum_procedure
      AFTER INSERT ON payslip_payables
      FOR EACH ROW
      EXECUTE PROCEDURE payslip_payables_validate_payables_amount_sum_procedure ();
    """)
  end
end
