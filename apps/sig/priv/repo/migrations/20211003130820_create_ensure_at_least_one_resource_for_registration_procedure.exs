defmodule Sig.Repo.Migrations.CreateEnsureAtLeastOneResourceForRegistrationProcedure do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION ensure_at_least_one_resource_for_registration ()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
      AS
    $$
    DECLARE
      registration_admission_date date;
      existing integer;
    BEGIN
      EXECUTE
        format('
          SELECT admission_date
          FROM employee_registrations
          WHERE
            org_id = $1.org_id AND
            id = $1.registration_id')
      USING OLD
      INTO registration_admission_date;

      EXECUTE
        format('
          SELECT 1
          FROM %1$I
          WHERE
            org_id = $1.org_id AND
            start_date = %2$L AND
            registration_id = $1.registration_id', TG_TABLE_NAME, registration_admission_date)
      USING OLD
      INTO existing;

      IF
        existing IS NULL
      THEN
        RAISE 'one record with `start_date` equal to `employee_registrations.admission_date` must exist'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      RETURN NULL;
    END;
    $$
    """)
  end

  def down do
    execute("DROP FUNCTION ensure_at_least_one_resource_for_registration;")
  end
end
