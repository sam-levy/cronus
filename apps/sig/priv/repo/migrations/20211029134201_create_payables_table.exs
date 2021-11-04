defmodule Sig.Repo.Migrations.CreatePayablesTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:payable_target, [:invoice, :payslip])

    create table(:payables) do
      add :org_id, references(:orgs), primary_key: true

      add :target, :payable_target, null: false
      add :due_date, :date, null: false
      add :reference_date, :date, null: false
      add :amount, :integer, null: false, default: 0
      add :is_fulfilled, :boolean, null: false, default: false
      add :method, :payment_method
      add :description, :string
      add :check_number, :string
      add :billet_barcode, :string
      add :note, :string

      add :authorized_by_id, references(:users)
      add :check_bank_account_id, references(:bank_accounts, with: [org_id: :org_id])
      add :credit_bank_account_id, references(:bank_accounts, with: [org_id: :org_id])

      timestamps()
    end

    create constraint(
             :payables,
             :payables_amount_positive,
             check: "amount >= 0"
           )

    create constraint(
             :payables,
             :payables_reference_date_beginning_of_month,
             check: "(extract (day from reference_date) = 1)"
           )

    create constraint(
             :payables,
             :payables_is_fulfilled_conditional,
             check: """
               CASE WHEN is_fulfilled THEN
                 method IS NOT NULL AND
                 authorized_by_id IS NOT NULL
               END
             """
           )

    create constraint(
             :payables,
             :payables_method_conditional,
             check: """
               CASE
                 WHEN method = 'check' THEN
                   check_number IS NOT NULL AND
                   check_bank_account_id IS NOT NULL

                 WHEN method = 'billet' THEN
                   billet_barcode IS NOT NULL

                 WHEN method = 'bank_transfer' THEN
                   credit_bank_account_id IS NOT NULL
               END
             """
           )

    # TODO: Add procedure to ensure a payable always have
    # a payslip or a bill.
  end
end
