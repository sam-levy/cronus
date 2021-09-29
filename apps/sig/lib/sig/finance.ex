defmodule Sig.Finance do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.EntityBankAccounts

  defdelegate list_banks, to: Banks
  defdelegate fetch_bank(routing_number), to: Banks

  defdelegate create_account_change(attrs), to: Accounts, as: :create_change
  defdelegate update_account_change(bank_account, attrs \\ %{}), to: Accounts, as: :update_change
  defdelegate fetch_account(entity, id), to: Accounts, as: :fetch
  defdelegate create_account(entity, attrs), to: Accounts, as: :create
  defdelegate update_account(account, attrs), to: Accounts, as: :update
  defdelegate list_accounts_by_entity(entity), to: Accounts, as: :list_by_entity
  defdelegate list_active_accounts_by_entity(entity), to: Accounts, as: :list_active_by_entity
  defdelegate subscribe_to_bank_accounts(entity), to: Accounts

  defdelegate create_entity_bank_account_change(attrs), to: EntityBankAccounts, as: :create_change

  defdelegate update_entity_bank_account_change(bank_account, attrs \\ %{}),
    to: EntityBankAccounts,
    as: :update_change

  defdelegate get_entity_bank_account_with_holder(entity, id),
    to: EntityBankAccounts,
    as: :get_with_holder

  defdelegate create_entity_bank_account(entity, attrs), to: EntityBankAccounts, as: :create
  defdelegate update_entity_bank_account(entity, attrs), to: EntityBankAccounts, as: :update

  defdelegate list_entity_bank_accounts_by_entity(entity),
    to: EntityBankAccounts,
    as: :list_by_entity_with_account

  defdelegate subscribe_to_entity_bank_accounts(entity), to: EntityBankAccounts

  def broadcast_accounts_and_relations(%Entity{} = entity) do
    Accounts.broadcast_bank_accounts(entity)
    EntityBankAccounts.broadcast_entity_bank_accounts(entity)
  end
end
