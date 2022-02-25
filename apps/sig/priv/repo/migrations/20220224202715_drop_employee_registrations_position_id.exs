defmodule Sig.Repo.Migrations.DropEmployeeRegistrationsPositionId do
  use Ecto.Migration

  def up do
    alter table(:employee_registrations) do
      remove :position_id
    end
  end

  def down do
  end
end
