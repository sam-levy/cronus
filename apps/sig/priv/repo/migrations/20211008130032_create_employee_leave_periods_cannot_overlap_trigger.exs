defmodule Sig.Repo.Migrations.CreateEmployeeLeavePeriodsCannotOverlapTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TRIGGER employee_leave_periods_cannot_overlap
      BEFORE INSERT OR UPDATE ON employee_leave_periods
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_no_period_overlap ();
    """)
  end

  def down do
    execute("DROP TRIGGER employee_leave_periods_cannot_overlap ON employee_leave_periods;")
  end
end
