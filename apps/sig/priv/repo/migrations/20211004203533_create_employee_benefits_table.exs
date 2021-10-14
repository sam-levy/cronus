defmodule Sig.Repo.Migrations.CreateEmployeeBenefitsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:employee_benefit_type, [
      :meal_voucher,
      :food_voucher,
      :transportation_voucher,
      :employee_health_insurance,
      :employee_dependents_health_insurance
    ])

    create table(:employee_benefits) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :description, :string
      add :type, :employee_benefit_type, null: false
      add :amount, :integer, null: false
      add :is_for_dependent, :boolean, null: false, default: false
      add :start_date, :date, null: false
      add :end_date, :date

      timestamps()
    end

    create constraint(
             :employee_benefits,
             :employee_benefits_amount_greater_than_zero,
             check: "amount > 0"
           )

    create constraint(
             :employee_benefits,
             :employee_benefits_start_date_before_end_date,
             check: "start_date < end_date"
           )
  end
end
