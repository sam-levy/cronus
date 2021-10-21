defmodule Sig.Repo.Migrations.CreatePayslipGroupTypeEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_group_type, [
      :regular,
      :first_13,
      :second_13,
      :vacation,
      :extra
    ])
  end
end
