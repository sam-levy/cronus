defmodule Sig.Repo.Migrations.CreateEnsureAtLeastOneCompanyAssignmentForRegistrationProcedure do
  use Ecto.Migration

  def up do
    execute("""
      CREATE OR REPLACE FUNCTION ensure_at_least_one_company_assignment_for_registration ()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
      AS
    $$
    BEGIN
      IF
        NOT EXISTS (
          SELECT 1
          FROM employee_company_assignments
          WHERE
            org_id = OLD.org_id AND
            registration_id = OLD.registration_id
        )
      THEN
        RAISE 'a registration must have at least one company assignment'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      RETURN NULL;
    END;
    $$
    """)

    execute("""
      CREATE TRIGGER ensure_at_least_one_company_assignment_for_registration_on_delete
      AFTER DELETE ON employee_company_assignments
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_at_least_one_company_assignment_for_registration ();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER ensure_at_least_one_company_assignment_for_registration_on_delete
      ON employee_company_assignments;
    """)
  end
end
