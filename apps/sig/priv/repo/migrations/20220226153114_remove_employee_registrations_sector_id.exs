defmodule Sig.Repo.Migrations.RemoveEmployeeRegistrationsSectorId do
  use Ecto.Migration

  def up do
    alter table(:employee_registrations) do
      remove :sector_id
    end
  end

  def down do
  end
end
