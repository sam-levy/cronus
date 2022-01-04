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
      add :financial_transaction_type, :financial_transaction_type
      add :description, :string
      add :check_number, :string
      add :billet_barcode, :string
      add :note, :string

      add :authorized_by_id, references(:users)
      add :check_debit_bank_account_id, references(:bank_accounts, with: [org_id: :org_id])
      add :credit_bank_account_id, references(:bank_accounts, with: [org_id: :org_id])
      add :financial_transaction_id, references(:financial_transactions, with: [org_id: :org_id])

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
             :financial_transaction_id_conditional,
             check: """
               CASE WHEN financial_transaction_id IS NOT NULL THEN
                 financial_transaction_type IS NOT NULL AND
                 authorized_by_id IS NOT NULL
               END
             """
           )

    create constraint(
             :payables,
             :payables_financial_transaction_type_conditional,
             check: """
               CASE
                 WHEN financial_transaction_type = 'check' THEN
                   check_number IS NOT NULL AND
                   check_debit_bank_account_id IS NOT NULL

                 WHEN financial_transaction_type = 'billet' THEN
                   billet_barcode IS NOT NULL

                 WHEN financial_transaction_type = 'bank_transfer' THEN
                   credit_bank_account_id IS NOT NULL
               END
             """
           )

    # TODO: Add procedure to ensure a payable always have
    # a payslip_payable or an invoice_payable.
  end
end
