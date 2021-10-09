defmodule Sig.Repo.Migrations.CreatePayslipCategoriesTable do
  use Ecto.Migration

  def change do
    create table(:payslip_categories) do
      add :org_id, references(:orgs), primary_key: true

      add :code, :citext, null: false
      add :description, :citext, null: false
      add :entry_type, :entry_type, null: false

      timestamps()
    end

    create unique_index(
             :payslip_categories,
             [:code, :org_id],
             name: :payslip_categories_code_unique
           )
  end
end
