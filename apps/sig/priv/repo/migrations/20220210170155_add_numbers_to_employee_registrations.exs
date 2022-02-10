defmodule Sig.Repo.Migrations.AddNumbersToEmployeeRegistrations do
  use Ecto.Migration

  def up do
    alter table(:employee_registrations) do
      add :number, :string
      add :e_social_number, :string
    end

    create unique_index(:employee_registrations, [:number, :org_id])
    create unique_index(:employee_registrations, [:e_social_number, :org_id])
  end

  def down do
    drop index(:employee_registrations, [:number, :org_id])
    drop index(:employee_registrations, [:e_social_number, :org_id])

    alter table(:employee_registrations) do
      remove :number
      remove :e_social_number
    end
  end
end
