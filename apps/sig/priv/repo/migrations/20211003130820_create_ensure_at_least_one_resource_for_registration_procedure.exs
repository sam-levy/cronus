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
      items_count integer;
    BEGIN
      EXECUTE
        format('
          SELECT COUNT(*)
          FROM %I
          WHERE
            org_id = $1.org_id AND
            registration_id = $1.registration_id', TG_TABLE_NAME)
      USING OLD
      INTO items_count;

      IF
        items_count = 0
      THEN
        RAISE 'a registration must have at least one item in %', TG_TABLE_NAME
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
