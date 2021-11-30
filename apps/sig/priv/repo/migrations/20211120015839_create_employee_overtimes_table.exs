defmodule Sig.Repo.Migrations.CreateEmployeeOvertimes do
  use Ecto.Migration

  def change do
    create table(:employee_overtimes) do
      add :org_id, references(:orgs), primary_key: true

      add :date, :date, null: false
      add :hours_amount, :string, null: false

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        null: false

      add :payslip_id, references(:payslips, with: [org_id: :org_id])

      timestamps()
    end

    create unique_index(
             :employee_overtimes,
             [:date, :registration_id, :org_id],
             name: :employee_overtimes_date_registration_unique
           )

    create constraint(
             :employee_overtimes,
             :employee_overtimes_date_beginning_of_month,
             check: "(extract (day from date) = 1)"
           )
  end
end
