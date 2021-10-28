defmodule Sig.Repo.Migrations.CreatePayslipsValidateAmountProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION validate_payslip_amount_on_update ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      DECLARE
        items_credit_amount_sum integer;
        items_debit_amount_sum integer;
      BEGIN
        SELECT SUM (amount)
        FROM payslip_items AS i
        LEFT JOIN
          payslip_categories AS c
          ON i.category_id = c.id
        WHERE
          i.payslip_id = NEW.id AND
          i.org_id = NEW.org_id AND
          (i.outside_item_entry_type = 'credit' OR c.entry_type = 'credit')
        INTO items_credit_amount_sum;

        SELECT SUM (amount)
        FROM payslip_items AS i
        LEFT JOIN
          payslip_categories AS c
          ON i.category_id = c.id
        WHERE
          i.payslip_id = NEW.id AND
          i.org_id = NEW.org_id AND
          (i.outside_item_entry_type = 'debit' OR c.entry_type = 'debit')
        INTO items_debit_amount_sum;

        IF
          coalesce(items_credit_amount_sum, 0) - coalesce(items_debit_amount_sum, 0) != NEW.amount
        THEN
          RAISE 'payslip items amount sum is different from payslip amount %', items_credit_amount_sum
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        RETURN NEW;
      END;
      $$
    """)

    execute("""
      CREATE TRIGGER validate_payslip_amount_on_update
      AFTER UPDATE ON payslips
      FOR EACH ROW
      EXECUTE PROCEDURE validate_payslip_amount_on_update ();
    """)
  end

  def down do
    execute("DROP TRIGGER validate_payslip_amount_on_update ON payslips;")
  end
end
