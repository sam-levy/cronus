defmodule Sig.Repo.Migrations.CreateEntityBankAccountsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:relationship_with_bank_account_holder, [
      :child,
      :spouse,
      :partner,
      :company_owner,
      :same_owner_company
    ])

    create table(:entities_bank_accounts, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true
      add :entity_id, references(:entities, with: [org_id: :org_id]), primary_key: true
      add :bank_account_id, references(:bank_accounts, with: [org_id: :org_id]), primary_key: true

      add :is_primary, :boolean, null: false
      add :is_joint_account_holder, :boolean, null: false
      add :relationship_with_holder, :relationship_with_bank_account_holder, null: false

      timestamps()
    end

    create unique_index(
             :entities_bank_accounts,
             [:entity_id, :is_primary, :org_id],
             where: "is_primary = true",
             name: :entities_bank_accounts_entity_is_primary
           )
  end
end
