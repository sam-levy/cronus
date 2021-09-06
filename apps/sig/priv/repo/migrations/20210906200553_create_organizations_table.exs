defmodule Sig.Repo.Migrations.CreateOrganizationsTable do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false

      timestamps()
    end
  end
end
