defmodule Sig.Finance do
  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Accounts

  defdelegate list_banks, to: Banks
  defdelegate fetch_bank(routing_number), to: Banks

  defdelegate create_account_change(attrs), to: Accounts, as: :create_change
  defdelegate update_account_change(bank_account, attrs \\ %{}), to: Accounts, as: :update_change
  defdelegate fetch_account(entity, id), to: Accounts, as: :fetch
  defdelegate create_account(entity, attrs), to: Accounts, as: :create
  defdelegate update_account(account, attrs), to: Accounts, as: :update
  defdelegate list_accounts_by_entity(entity), to: Accounts, as: :list_by_entity
  defdelegate subscribe_to_bank_accounts(entity), to: Accounts
  defdelegate broadcast_bank_accounts(entity), to: Accounts
end
