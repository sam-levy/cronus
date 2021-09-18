defmodule Sig.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :org_id, references(:orgs), primary_key: true

      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      add :individual_id, references(:entities, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(:users, [:email, :org_id])
    create unique_index(:users, [:individual_id, :org_id])

    create table(:users_tokens) do
      add :org_id, references(:orgs), primary_key: true

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      add :user_id, references(:users, with: [org_id: :org_id], on_delete: :delete_all),
        null: false

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id, :org_id])
    create unique_index(:users_tokens, [:context, :token, :org_id])
  end
end
