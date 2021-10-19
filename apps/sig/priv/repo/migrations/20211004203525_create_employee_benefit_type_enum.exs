defmodule Sig.Repo.Migrations.CreateEmployeeBenefitTypeEnum do
  use Ecto.Migration

  import EctoEnumMigration

  def change do
    create_type(:employee_benefit_type, [
      :meal_voucher,
      :food_voucher,
      :transportation_voucher,
      :health_insurance
    ])
  end
end
