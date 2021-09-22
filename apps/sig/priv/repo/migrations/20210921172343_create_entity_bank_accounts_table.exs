defmodule Sig.Repo.Migrations.CreateEntityBankAccountsTable do
  use Ecto.Migration
  import EctoEnumMigration

  def change do
    create_type(:relationship_with_bank_account_holder, [:child, :spouse, :partner])

    create table(:entities_bank_accounts, primary_key: false) do
      add :org_id, references(:orgs), primary_key: true
      add :entity_id, references(:entities, with: [org_id: :org_id]), primary_key: true

      add :bank_account_id,
          references(:bank_accounts, with: [org_id: :org_id, entity_id: :entity_id]),
          primary_key: true

      add :is_primary, :boolean, null: false, default: false
      add :is_active, :boolean, null: false, default: true
      add :is_joint_account_holder, :boolean, null: false, default: true
      add :relationship_with_holder, :relationship_with_bank_account_holder

      timestamps()
    end

    create unique_index(
             :entities_bank_accounts,
             [:entity_id, :is_primary, :org_id],
             where: "is_primary = true",
             name: :entities_bank_accounts_entity_is_primary
           )

    create constraint(
             :entities_bank_accounts,
             :relationship_with_holder_conditional_constaint,
             check: """
             CASE WHEN is_joint_account_holder = false THEN
               relationship_with_holder IS NOT NULL
             ELSE
               relationship_with_holder IS NULL
             END
             """
           )
  end
end
