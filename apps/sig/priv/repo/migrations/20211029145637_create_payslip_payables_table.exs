defmodule Sig.Repo.Migrations.CreatePayslipPayablesTable do
  use Ecto.Migration

  def change do
    create table(:payslip_payables, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true
      add :payslip_id, references(:payslips, with: [org_id: :org_id]), primary_key: true
      add :payable_id, references(:payables, with: [org_id: :org_id]), primary_key: true

      add :is_auto_adjustable_amount, :boolean, null: false, default: false
    end

    create unique_index(
             :payslip_payables,
             [:is_auto_adjustable_amount, :payslip_id, :org_id],
             where: "is_auto_adjustable_amount = true",
             name: :payslip_payables_is_auto_adjustable_amount_true_unique
           )

    create unique_index(
             :payslip_payables,
             [:payable_id, :org_id],
             name: :payslip_payables_payable_unique
           )
  end
end
