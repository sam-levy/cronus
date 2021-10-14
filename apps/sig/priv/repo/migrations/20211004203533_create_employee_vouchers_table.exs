defmodule Sig.Repo.Migrations.CreateEmployeeVouchersTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:employee_voucher_type, [
      :transport,
      :meal,
      :food,
      :employee_health_insurance,
      :employee_dependents_health_insurance
    ])

    create table(:employee_vouchers) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :type, :employee_voucher_type, null: false
      add :amount, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date

      timestamps()
    end

    create constraint(
             :employee_vouchers,
             :employee_vouchers_amount_greater_than_zero,
             check: "amount > 0"
           )

    create constraint(
             :employee_vouchers,
             :employee_vouchers_start_date_before_end_date,
             check: "start_date < end_date"
           )
  end
end
