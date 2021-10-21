defmodule Sig.Repo.Migrations.CreateEnsureNoPeriodOverlapWithRegistrationTriggerFunction do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION ensure_no_period_overlap_with_registration ()
      RETURNS TRIGGER
      LANGUAGE PLPGSQL
      AS
    $$
    DECLARE
      previous_end_date date;
      next_start_date date;
    BEGIN
      EXECUTE
        format('
          SELECT
            MAX (end_date)
          FROM
            %I
          WHERE
            id != $1.id AND
            org_id = $1.org_id AND
            registration_id = $1.registration_id AND
            start_date <= $1.start_date', TG_TABLE_NAME)
      USING NEW
      INTO previous_end_date;

      EXECUTE
        format('
          SELECT
            MIN (start_date)
          FROM
            %I
          WHERE
            id != $1.id AND
            org_id = $1.org_id AND
            registration_id = $1.registration_id AND
            start_date > $1.start_date', TG_TABLE_NAME)
      USING NEW
      INTO next_start_date;

      IF
        previous_end_date >= NEW.start_date
      THEN
        RAISE 'start_date before or equal to an existing record end_date'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      IF
        next_start_date <= NEW.end_date
      THEN
        RAISE 'end_date after or equal to an existing record start_date'
        USING ERRCODE = 'integrity_constraint_violation';
      END IF;

      RETURN NEW;
    END;
    $$
    """)
  end

  def down do
    execute("DROP FUNCTION ensure_no_period_overlap_with_registration;")
  end
end
