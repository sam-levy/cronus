defmodule Sig.Repo.Migrations.AddSectorIdToEmployeeCompanyAssignments do
  use Ecto.Migration

  def up do
    alter table(:employee_company_assignments) do
      add :sector_id, references(:org_sectors, with: [org_id: :org_id]), null: false
    end
  end

  def down do
    remove :sector_id
  end
end
