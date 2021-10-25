defmodule Sig.Repo.Migrations.CreatePayslipsChangeAmountToZeroProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION change_payslip_amount_to_zero ()
        RETURNS TRIGGER
        LANGUAGE PLPGSQL
        AS
      $$
      BEGIN
        NEW.amount = 0;
        RETURN NEW;
      END;
      $$
    """)

    execute("""
      CREATE TRIGGER change_payslip_amount_to_zero
      BEFORE INSERT ON payslips
      FOR EACH ROW
      EXECUTE PROCEDURE change_payslip_amount_to_zero ();
    """)
  end

  def down do
    execute("DROP TRIGGER change_payslip_amount_to_zero ON payslips;")
  end
end
