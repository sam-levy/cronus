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
        payslip_amount integer;
        payables_amount_sum integer;
        payment_in_advance_payslip_items_amount_sum integer;
      BEGIN
        IF
          NEW.target != 'payslip'
        THEN
          RETURN NEW;
        END IF;

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

        SELECT SUM (payables.amount)
        FROM payables
        LEFT JOIN
          payslip_payables
          ON payslip_payables.payable_id = payables.id
        LEFT JOIN
          payslips
          ON payslips.id = payslip_payables.payslip_id
        WHERE
          payslip_payables.payslip_id = (SELECT payslip_id FROM payslip_payables WHERE payable_id = NEW.id) AND
          payables.org_id = NEW.org_id
        INTO payables_amount_sum;

        SELECT SUM (payslip_items.amount)
        FROM payables
        LEFT JOIN
          payslip_payables
          ON payslip_payables.payable_id = payables.id
        LEFT JOIN
          payslips
          ON payslips.id = payslip_payables.payslip_id
        LEFT JOIN
          payslip_items
          ON payslip_items.payslip_id = payslips.id
        WHERE
          payslip_payables.payable_id = NEW.id AND
          payslip_items.org_id = NEW.org_id AND
          payslip_items.entry_type = 'debit' AND
          payslip_items.is_payment_advance = true
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
      CREATE TRIGGER payables_validate_amount_sum_for_payslip_procedure
      AFTER UPDATE ON payables
      FOR EACH ROW
      EXECUTE PROCEDURE payables_validate_amount_sum_for_payslip_procedure ();
    """)
  end

  def down do
    execute("DROP TRIGGER payables_validate_amount_sum_for_payslip_procedure ON payables;")
  end
end
