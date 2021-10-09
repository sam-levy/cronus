defmodule Sig.Repo.Migrations.CreateEntryTypeEnum do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:entry_type, [:credit, :debit])
  end
end
