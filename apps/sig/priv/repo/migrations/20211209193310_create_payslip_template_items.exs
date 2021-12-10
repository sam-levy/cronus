defmodule Sig.Repo.Migrations.CreatePayslipTemplateItems do
  use Ecto.Migration

  def change do
    create table(:payslip_template_items) do
      add :org_id, references(:orgs), primary_key: true

      add :payslip_template_id, references(:payslip_templates, with: [org_id: :org_id]),
        null: false

      add :payslip_recurring_item_model_id,
          references(:payslip_recurring_item_models, with: [org_id: :org_id]),
          null: false
    end

    create unique_index(
             :payslip_template_items,
             [:payslip_recurring_item_model_id, :payslip_template_id, :org_id],
             name: :payslip_template_items_model_unique
           )
  end
end
