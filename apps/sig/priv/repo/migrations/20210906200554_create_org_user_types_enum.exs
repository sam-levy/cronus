defmodule Sig.Repo.Migrations.CreateOrgUserTypesEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:org_user_types, [:admin, :regular])
  end
end
