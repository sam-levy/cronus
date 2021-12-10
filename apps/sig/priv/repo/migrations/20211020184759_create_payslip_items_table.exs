defmodule Sig.Repo.Migrations.CreatePayslipItemsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payslip_item_type, [:payslip_item, :outside_item])

    create table(:payslip_items) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :payslip_item_type, null: false
      add :code, :citext
      add :reference, :string
      add :description, :string, null: false
      add :entry_type, :entry_type, null: false
      add :amount, :integer, null: false
      add :is_payment_advance, :boolean, null: false, default: false

      add :payslip_id, references(:payslips, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(
             :payslip_items,
             [:code, :payslip_id, :org_id],
             name: :payslip_items_code_unique
           )

    create constraint(
             :payslip_items,
             :payslip_items_amount_positive,
             check: "amount >= 0"
           )

    create constraint(
             :payslip_items,
             :payslip_items_is_payment_advance_entry_type_debit,
             check: "CASE WHEN is_payment_advance THEN entry_type = 'debit' END"
           )

    create constraint(
             :payslip_items,
             :payslip_items_conditional,
             check: """
               CASE
                 WHEN type = 'payslip_item' THEN
                   code IS NOT NULL

                 WHEN type = 'outside_item' THEN
                   code IS NULL AND
                   reference IS NULL
               END
             """
           )

    # TODO: Add trigger to ensure the sum of the amounts is
    # equal to the payslip amount. Must be a deffered trigger
    # which is tricky to implement for ecto.
  end
end
