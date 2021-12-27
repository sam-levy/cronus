defmodule Sig.Repo.Migrations.CreatePayslipTemplateItems do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_template_item_type, [:payslip_item, :payslip_item_model])

    create table(:payslip_template_items) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :payslip_template_item_type, null: false
      add :amount, :integer

      add :payslip_category_id, references(:payslip_categories, with: [org_id: :org_id])

      add :payslip_recurring_item_model_id,
          references(:payslip_recurring_item_models, with: [org_id: :org_id])

      add :payslip_template_id, references(:payslip_templates, with: [org_id: :org_id]),
        null: false

      timestamps()
    end

    create unique_index(
             :payslip_template_items,
             [:payslip_category_id, :payslip_template_id, :org_id],
             name: :payslip_template_items_category_unique
           )

    create unique_index(
             :payslip_template_items,
             [:payslip_recurring_item_model_id, :payslip_template_id, :org_id],
             name: :payslip_template_items_model_unique
           )

    create constraint(
             :payslip_template_items,
             :payslip_template_items_positive_amount,
             check: "amount >= 0"
           )

    create constraint(
             :payslip_template_items,
             :payslip_template_items_conditional,
             check: """
               CASE
                 WHEN type = 'payslip_item' THEN
                   amount IS NOT NULL AND
                   payslip_category_id IS NOT NULL AND
                   payslip_recurring_item_model_id IS NULL

                 WHEN type = 'payslip_item_model' THEN
                   payslip_recurring_item_model_id IS NOT NULL AND
                   amount IS NULL AND
                   payslip_category_id IS NULL
               END
             """
           )
  end
end
