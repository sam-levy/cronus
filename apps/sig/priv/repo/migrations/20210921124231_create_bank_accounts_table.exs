defmodule Sig.Repo.Migrations.CreateBankAccountsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:bank_account_type, [:checking_account, :savings_account, :salary_account])

    create table(:bank_accounts) do
      add :org_id, references(:orgs), primary_key: true

      add :type, :bank_account_type, null: false
      add :routing_number, :citext, null: false
      add :branch_number, :citext, null: false
      add :number, :citext, null: false
      add :other_info, :map, null: false, default: %{}
      add :is_active, :boolean, null: false, default: true
      add :is_joint_account, :boolean, null: false, default: false
      add :pix_key, :citext

      timestamps()
    end

    create unique_index(:bank_accounts, [:pix_key, :org_id])

    create unique_index(
      :bank_accounts,
      [:org_id, :routing_number, :branch_number, :number],
      name: :bank_accounts_org_id_account
    )
  end
end
