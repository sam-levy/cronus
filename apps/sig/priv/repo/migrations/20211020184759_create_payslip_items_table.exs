defmodule Sig.Repo.Migrations.CreatePayslipItemsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_item_type, [:payslip_item, :outside_item])

    create table(:payslip_items) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :payslip_item_type, null: false
      add :reference, :string
      add :outside_item_description, :string
      add :outside_item_entry_type, :entry_type
      add :amount, :integer, null: false

      add :payslip_id, references(:payslips, with: [org_id: :org_id]), null: false

      add :category_id,
          references(:payslip_categories,
            with: [org_id: :org_id],
            name: :payslip_items_category
          )

      timestamps()
    end

    create unique_index(
             :payslip_items,
             [:category_id, :payslip_id, :org_id],
             name: :payslip_items_category_unique
           )

    create constraint(
             :payslip_items,
             :payslip_items_amount_positive,
             check: "amount >= 0"
           )

    create constraint(
             :payslip_items,
             :payslip_items_conditional,
             check: """
               CASE
                 WHEN type = 'payslip_item' THEN
                   category_id IS NOT NULL AND
                   outside_item_description IS NULL AND
                   outside_item_entry_type IS NULL

                 WHEN type = 'outside_item' THEN
                   category_id IS NULL AND
                   reference IS NULL AND
                   outside_item_description IS NOT NULL AND
                   outside_item_entry_type IS NOT NULL
               END
             """
           )
  end

  # TODO: Add a trigger function on to ensure that the payslip amount
  # is the sum of the amounts of its items.
end
