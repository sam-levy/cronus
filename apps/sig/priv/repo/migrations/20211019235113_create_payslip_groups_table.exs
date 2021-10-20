defmodule Sig.Repo.Migrations.CreatePayslipGroupsTable do
  use Ecto.Migration

  def change do
    create table(:payslip_groups) do
      add :org_id, references(:orgs), primary_key: true

      add :date, :date, null: false
      add :type, :payslip_group_type, null: false

      timestamps()
    end

    create unique_index(
             :payslip_groups,
             [:date, :type, :org_id],
             name: :payslip_groups_date_unique
           )

    create constraint(
             :payslip_groups,
             :payslip_groups_date_first_day_of_month,
             check: "(extract (day from date) = 1)"
           )
  end
end
