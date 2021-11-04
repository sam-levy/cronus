defmodule Sig.Repo.Migrations.CreatePayablesValidateAmountSumForPayslipProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION payables_validate_amount_sum_for_payslip_procedure ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      DECLARE
        payables_amount_sum integer;
        payslip_amount integer;
      BEGIN
        IF
          NEW.target != 'payslip'
        THEN
          RETURN NEW;
        END IF;

        SELECT SUM (payables.amount)
        FROM payables
        LEFT JOIN
          payslip_payables
          ON payslip_payables.payable_id = payables.id
        WHERE
          payslip_payables.payable_id = NEW.id AND
          payslip_payables.org_id = NEW.org_id
        INTO payables_amount_sum;

        SELECT payslips.amount
        FROM payables
        LEFT JOIN
          payslip_payables
          ON payslip_payables.payable_id = payables.id
        LEFT JOIN
          payslips
          ON payslips.id = payslip_payables.payslip_id
        WHERE
          payslip_payables.payable_id = NEW.id AND
          payslips.org_id = NEW.org_id
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
      CREATE TRIGGER payables_validate_amount_sum_for_payslip_procedure
      AFTER UPDATE ON payables
      FOR EACH ROW
      EXECUTE PROCEDURE payables_validate_amount_sum_for_payslip_procedure ();
    """)
  end
end
