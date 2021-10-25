defmodule Sig.Repo.Migrations.CreatePayslipItemsValidatePayslipIsOpenProcedures do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION validate_payslip_is_open_for_payslip_item_insert ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      BEGIN
        IF
          EXISTS (
            SELECT 1
            FROM payslips
            WHERE
              id IN (SELECT payslip_id FROM new_table) AND
              org_id IN (SELECT org_id FROM new_table) AND
              is_closed = true
          )
        THEN
          RAISE 'closed payslip cannot be updated'
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        RETURN NULL;
      END;
      $$
    """)

    execute("""
      CREATE OR REPLACE FUNCTION validate_payslip_is_open_for_payslip_item_update_or_delete ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      BEGIN
        IF
          EXISTS (
            SELECT 1
            FROM payslips
            WHERE
              id IN (SELECT payslip_id FROM old_table) AND
              org_id IN (SELECT org_id FROM old_table) AND
              is_closed = true
          )
        THEN
          RAISE 'closed payslip cannot be updated'
          USING ERRCODE = 'integrity_constraint_violation';
        END IF;

        RETURN NULL;
      END;
      $$
    """)

    execute("""
      CREATE TRIGGER validate_payslip_is_open_for_payslip_item_insert
      AFTER INSERT ON payslip_items
      REFERENCING NEW TABLE AS new_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE validate_payslip_is_open_for_payslip_item_insert ();
    """)

    execute("""
      CREATE TRIGGER validate_payslip_is_open_for_payslip_item_update
      AFTER UPDATE ON payslip_items
      REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE validate_payslip_is_open_for_payslip_item_update_or_delete ();
    """)

    execute("""
      CREATE TRIGGER validate_payslip_is_open_for_payslip_item_delete
      AFTER DELETE ON payslip_items
      REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE PROCEDURE validate_payslip_is_open_for_payslip_item_update_or_delete ();
    """)
  end

  def down do
    execute("DROP TRIGGER validate_payslip_is_open_for_payslip_item_insert ON payslip_items;")
    execute("DROP TRIGGER validate_payslip_is_open_for_payslip_item_update ON payslip_items;")
    execute("DROP TRIGGER validate_payslip_is_open_for_payslip_item_delete ON payslip_items;")
  end
end
