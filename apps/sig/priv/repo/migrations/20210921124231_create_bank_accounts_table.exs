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
      add :is_active, :boolean, null: false
      add :is_primary, :boolean, null: false
      add :is_joint_account, :boolean, null: false
      add :pix_key, :citext

      add :entity_id, references(:entities, with: [org_id: :org_id]), null: false

      timestamps()
    end

    create unique_index(:bank_accounts, [:pix_key, :org_id])

    create unique_index(
      :bank_accounts,
      [:routing_number, :branch_number, :number, :org_id],
      name: :bank_accounts_org_id_account
    )

    create unique_index(
      :bank_accounts,
      [:is_primary, :entity_id, :org_id],
      where: "is_primary = true",
      name: :bank_accounts_is_primary
    )
  end
end
