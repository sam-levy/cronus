defmodule Sig.Repo.Migrations.CreatePayslipGroupTypeEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_group_type, [:regular, :vacation, :extra])
  end
end
