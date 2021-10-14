defmodule Sig.Repo.Migrations.CreateEmployeeRegistrationRecurringPayslipItemsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:employee_registration_recurring_payslip_item_type, [
      :payslip_item,
      :payslip_item_model,
      :outside_item
    ])

    create table(:employee_registration_recurring_payslip_items) do
      add :org_id, references(:orgs), primary_key: true

      add :registration_id, references(:employee_registrations, with: [org_id: :org_id]),
        primary_key: true

      add :type, :employee_registration_recurring_payslip_item_type, null: false

      add :payslip_recurring_item_model_id,
          references(:payslip_recurring_item_models,
            with: [org_id: :org_id],
            name: :employee_registration_recurring_payslip_items_item_model
          )

      add :payslip_category_id,
          references(:payslip_categories,
            with: [org_id: :org_id],
            name: :employee_registration_recurring_payslip_items_category
          )

      add :outside_item_description, :citext
      add :outside_item_entry_type, :entry_type

      add :item_amount, :integer

      timestamps()
    end

    create unique_index(
             :employee_registration_recurring_payslip_items,
             [
               :outside_item_description,
               :registration_id,
               :org_id
             ],
             name: :employee_registration_recurring_payslip_items_description
           )

    create constraint(
             :employee_registration_recurring_payslip_items,
             :employee_registration_recurring_payslip_items_positive_amount,
             check: "item_amount >= 0"
           )

    create constraint(
             :employee_registration_recurring_payslip_items,
             :employee_registration_recurring_payslip_items_conditional,
             check: """
               CASE
                 WHEN type = 'payslip_item' THEN
                   item_amount IS NOT NULL AND
                   payslip_category_id IS NOT NULL AND
                   payslip_recurring_item_model_id IS NULL AND
                   outside_item_description IS NULL AND
                   outside_item_entry_type IS NULL

                 WHEN type = 'payslip_item_model' THEN
                   payslip_recurring_item_model_id IS NOT NULL AND
                   item_amount IS NULL AND
                   payslip_category_id IS NULL AND
                   outside_item_description IS NULL AND
                   outside_item_entry_type IS NULL

                 WHEN type = 'outside_item' THEN
                   item_amount IS NOT NULL AND
                   outside_item_description IS NOT NULL AND
                   outside_item_entry_type IS NOT NULL AND
                   payslip_recurring_item_model_id IS NULL AND
                   payslip_category_id IS NULL
               END
             """
           )
  end
end
