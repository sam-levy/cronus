defmodule Sig.Repo.Migrations.CreatePayslipsTable do
  use Ecto.Migration

  def change do
    create table(:payslips) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :payslip_group_type, null: false
      add :amount, :integer, null: false, default: 0
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :is_closed, :boolean, null: false, default: false

      add :group_id, references(:payslip_groups, with: [org_id: :org_id]), null: false

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        null: false

      timestamps()
    end

    create constraint(
             :payslips,
             :payslips_amount_positive,
             check: "amount >= 0"
           )

    create constraint(
             :payslips,
             :payslips_start_date_before_end_date,
             check: "start_date < end_date"
           )
  end
end
