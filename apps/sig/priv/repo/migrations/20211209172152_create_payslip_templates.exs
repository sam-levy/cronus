defmodule Sig.Repo.Migrations.CreatePayslipTemplates do
  use Ecto.Migration

  def change do
    create table(:payslip_templates) do
      add :org_id, references(:orgs), primary_key: true

      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(
             :payslip_templates,
             [:name, :org_id],
             name: :payslip_templates_name_unique
           )
  end
end
