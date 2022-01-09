defmodule Sig.Finance do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Payables
  alias Sig.Finance.FinancialTransactions

  defdelegate list_banks, to: Banks
  defdelegate fetch_bank(routing_number), to: Banks
  defdelegate fetch_entity_active_primary_bank_account(entity), to: Banks
  defdelegate list_active_bank_accounts_by_entity(entity), to: Banks

  defdelegate create_account_change(attrs), to: Accounts, as: :create_change
  defdelegate update_account_change(bank_account, attrs \\ %{}), to: Accounts, as: :update_change
  defdelegate fetch_account(entity, id), to: Accounts, as: :fetch
  defdelegate create_account(entity, attrs), to: Accounts, as: :create
  defdelegate update_account(account, attrs), to: Accounts, as: :update
  defdelegate list_accounts_by(schema, opts \\ []), to: Accounts, as: :list_by
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

  defdelegate list_active_entity_bank_accounts_by_entity_with_holder(entity),
    to: EntityBankAccounts,
    as: :list_active_by_entity_with_holder

  defdelegate list_active_entity_bank_accounts_by_entity_with_account(entity),
    to: EntityBankAccounts,
    as: :list_active_by_entity_with_account

  defdelegate entities_relationships(entity_1, entity_2), to: EntityBankAccounts
  defdelegate subscribe_to_entity_bank_accounts(entity), to: EntityBankAccounts

  defdelegate set_payable_changeset_financial_transaction_type(
                changeset,
                financial_transaction_type
              ),
              to: Payables,
              as: :set_changeset_financial_transaction_type

  defdelegate default_payable_preloads, to: Payables, as: :default_preloads
  defdelegate list_payables_by(schema, opts \\ []), to: Payables, as: :list_by
  defdelegate subscribe_to_payables(schema), to: Payables
  defdelegate subscribe_to_payables(org, due_date_start, due_date_end), to: Payables
  defdelegate unsubscribe_from_payables(schema), to: Payables
  defdelegate unsubscribe_from_payables(org, due_date_start, due_date_end), to: Payables
  defdelegate broadcast_new_payables(payslip), to: Payables
  defdelegate broadcast_new_payable(payable), to: Payables
  defdelegate broadcast_updated_payables(schema), to: Payables
  defdelegate broadcast_deleted_payable(payable), to: Payables

  defdelegate authorize_payable_for_payslip(payslip, payable, user), to: Payables
  defdelegate unauthorize_payable_for_payslip(payable), to: Payables
  defdelegate create_payable_for_payslip(payslip, attrs, opts \\ []), to: Payables
  defdelegate create_payables_for_payslip(registration, payslip, items, opts \\ []), to: Payables
  defdelegate update_payable_for_payslip(payslip, payable, attrs), to: Payables
  defdelegate delete_payable_for_payslip(payslip, payable), to: Payables
  defdelegate create_payable_for_payslip_change(attrs \\ %{}), to: Payables
  defdelegate update_payable_for_payslip_change(payable, attrs \\ %{}), to: Payables
  defdelegate get_payable(payslip, id, opts \\ []), to: Payables, as: :get
  defdelegate fetch_payable(payslip, id, opts \\ []), to: Payables, as: :fetch
  defdelegate set_payable_for_payslip_as_auto_adjustable(payslip, payable), to: Payables
  defdelegate unset_payable_for_payslip_as_auto_adjustable(payslip, payable), to: Payables

  defdelegate pay_payables_change(params \\ %{}), to: FinancialTransactions
  defdelegate pay_payables(org, attrs \\ %{}), to: FinancialTransactions

  def broadcast_accounts_and_relations(%Entity{} = entity) do
    Accounts.broadcast_bank_accounts(entity)
    EntityBankAccounts.broadcast_entity_bank_accounts(entity)
  end
end
