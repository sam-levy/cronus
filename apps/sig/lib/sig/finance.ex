defmodule Sig.Finance do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Payables

  defdelegate list_banks, to: Banks
  defdelegate fetch_bank(routing_number), to: Banks

  defdelegate create_account_change(attrs), to: Accounts, as: :create_change
  defdelegate update_account_change(bank_account, attrs \\ %{}), to: Accounts, as: :update_change
  defdelegate fetch_account(entity, id), to: Accounts, as: :fetch

  defdelegate fetch_account_in_org_with_entity(org, id),
    to: Accounts,
    as: :fetch_in_org_with_entity

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

  defdelegate entities_relationships(entity_1, entity_2), to: EntityBankAccounts
  defdelegate subscribe_to_entity_bank_accounts(entity), to: EntityBankAccounts

  defdelegate authorize_payable(payable, attrs), to: Payables, as: :authorize
  defdelegate unauthorize_payable(payable), to: Payables, as: :unauthorize
  defdelegate create_payable_for_payslip(payslip, attrs), to: Payables
  defdelegate delete_payable_for_payslip(payslip, payable), to: Payables
  defdelegate set_payslip_payable_is_auto_adjustable_amount(payslip, payable_id), to: Payables
  defdelegate create_payable_for_payslip_change(attrs \\ %{}), to: Payables
  defdelegate update_payable_for_payslip_change(payable, attrs \\ %{}), to: Payables
  defdelegate list_by_payslip(payslip), to: Payables
  defdelegate get_by_payslip(payslip, id), to: Payables
  defdelegate subscribe_to_payables_for_payslip(payslip), to: Payables
  defdelegate unsubscribe_from_payables_for_payslip(payslip), to: Payables
  defdelegate broadcast_payables_for_payslip(payslip), to: Payables

  def broadcast_accounts_and_relations(%Entity{} = entity) do
    Accounts.broadcast_bank_accounts(entity)
    EntityBankAccounts.broadcast_entity_bank_accounts(entity)
  end
end
