defmodule Sig.Repo.Migrations.CreatePayslipCategoriesTable do
  use Ecto.Migration

  def change do
    create table(:payslip_categories) do
      add :org_id, references(:orgs), primary_key: true

      add :code, :citext, null: false
      add :description, :citext, null: false
      add :entry_type, :entry_type, null: false
      add :is_payment_advance, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(
             :payslip_categories,
             [:code, :org_id],
             name: :payslip_categories_code_unique
           )

    create constraint(
             :payslip_categories,
             :payslip_categories_is_payment_advance_entry_type_debit,
             check: "CASE WHEN is_payment_advance THEN entry_type = 'debit' END"
           )
  end
end
