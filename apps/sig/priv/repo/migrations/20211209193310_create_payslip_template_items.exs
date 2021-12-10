defmodule Sig.Repo.Migrations.CreatePayslipTemplateItems do
  use Ecto.Migration

  def change do
    create table(:payslip_template_items, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true

      add :payslip_template_id, references(:payslip_templates, with: [org_id: :org_id]),
        primary_key: true

      add :payslip_recurring_item_model_id,
          references(:payslip_recurring_item_models, with: [org_id: :org_id]),
          primary_key: true
    end
  end
end
