defmodule Sig.Repo.Migrations.CreateEmployeeRegistrationsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:employee_resignation_type, [:resigned, :dismissal, :dismissal_due_cause])

    create table(:employee_registrations) do
      add :org_id, references(:orgs), primary_key: true

      add :admission_date, :date, null: false
      add :resignation_date, :date
      add :resignation_type, :employee_resignation_type

      add :sector_id, references(:org_sectors, with: [org_id: :org_id]), null: false
      add :position_id, references(:org_positions, with: [org_id: :org_id]), null: false
      add :individual_id, references(:entities, with: [org_id: :org_id]), null: false
      add :registered_at_id, references(:entities, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(
             :employee_registrations,
             [:registered_at_id, :individual_id, :org_id],
             where: "resignation_date IS NULL",
             name: :employee_registrations_resignation_date_is_null_unique
           )

    create constraint(
             :employee_registrations,
             :resignation_type_required_if_resignation_date_not_null,
             check: """
             CASE WHEN resignation_date IS NOT NULL THEN
               resignation_type IS NOT NULL
             ELSE
               resignation_type IS NULL
             END
             """
           )

    create constraint(
             :employee_registrations,
             :employee_registrations_admission_before_resignation,
             check: "admission_date < resignation_date"
           )
  end
end
