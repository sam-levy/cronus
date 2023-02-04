defmodule Sig.Repo.Migrations.CreateInvoicesTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:invoice_type, [:goods_and_services, :tax])

    create table(:invoices) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :invoice_type, null: false
      add :nfe_access_key, :string, size: 44
      add :number, :string, size: 9
      add :issue_date, :date, null: false
      add :delivery_date, :date
      add :amount, :integer, null: false

      add :invoiced_by_id, references(:entities, with: [org_id: :org_id]), null: false
      add :invoiced_to_id, references(:entities, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(:invoices, :nfe_access_key)

    create unique_index(
             :invoices,
             [:number, :invoiced_by_id],
             name: :invoices_number_invoiced_by_id_unique
           )

    create constraint(
             :invoices,
             :invoices_amount_positive_positive,
             check: "amount >= 0"
           )
  end
end
