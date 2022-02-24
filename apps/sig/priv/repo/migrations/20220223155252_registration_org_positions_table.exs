defmodule Sig.Repo.Migrations.CreateRegistrationOrgPositionsTable do
  use Ecto.Migration

  def up do
    create table(:registration_org_positions) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        null: false

      add :position_id, references(:org_positions, with: [org_id: :org_id]), null: false

      add :start_date, :date, null: false

      timestamps()
    end

    create unique_index(
             :registration_org_positions,
             [:start_date, :position_id, :registration_id, :org_id],
             name: :registration_org_positions_start_date
           )

    execute("""
      CREATE TRIGGER ensure_at_least_one_registration_org_position_for_registration_on_delete
      AFTER DELETE ON registration_org_positions
      FOR EACH ROW
      EXECUTE PROCEDURE ensure_at_least_one_resource_for_registration ();
    """)
  end

  def down do
    execute("""
      DROP TRIGGER ensure_at_least_one_registration_org_position_for_registration_on_delete
      ON registration_org_positions;
    """)

    drop index(:registration_org_positions, [:start_date, :position_id, :registration_id, :org_id])

    drop table(:registration_org_positions)
  end
end
