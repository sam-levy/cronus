defmodule Sig.Repo.Migrations.AddNullFalseToEmployeeCompanyAssignmentsSectorId do
  use Ecto.Migration

  def change do
    alter table(:employee_company_assignments) do
      modify :sector_id, references(:org_sectors, with: [org_id: :org_id]),
        null: false,
        from: references(:org_sectors, with: [org_id: :org_id])
    end
  end
end
