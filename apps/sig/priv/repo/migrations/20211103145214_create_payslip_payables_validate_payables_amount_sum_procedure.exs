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
        payslip_amount integer;
        payables_amount_sum integer;
        payment_in_advance_payslip_items_amount_sum integer;
      BEGIN
        SELECT amount
        FROM payslips
        WHERE
          id = NEW.payslip_id AND
          org_id = NEW.org_id
        INTO payslip_amount;

        SELECT SUM (payables.amount)
        FROM payslip_payables
        LEFT JOIN
          payables
          ON payables.id = payslip_payables.payable_id
        WHERE
          payslip_payables.payslip_id = NEW.payslip_id AND
          payslip_payables.org_id = NEW.org_id
        INTO payables_amount_sum;

        SELECT SUM (amount)
        FROM payslip_items
        WHERE
          payslip_id = NEW.payslip_id AND
          org_id = NEW.org_id AND
          entry_type = 'debit' AND
          is_payment_advance = true
        INTO payment_in_advance_payslip_items_amount_sum;

        IF
          coalesce(payables_amount_sum, 0) > coalesce(payslip_amount, 0) + coalesce(payment_in_advance_payslip_items_amount_sum, 0)
        THEN
          RAISE 'payables amount sum cannot exceed the payslip amount plus payments in advance items'
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

  def down do
    execute(
      "DROP TRIGGER payslip_payables_validate_payables_amount_sum_procedure ON payslip_payables;"
    )
  end
end
