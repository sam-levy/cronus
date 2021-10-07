defmodule Sig.Repo.Migrations.CreateEmployeeSuspensionsTable do
  use Ecto.Migration

  def change do
    create table(:employee_suspensions) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :description, :string, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false

      timestamps()
    end

    create constraint(
      :employee_suspensions,
      :employee_suspensions_start_date_before_or_equal_end_date,
      check: "start_date <= end_date"
    )
  end
end
