defmodule Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction do
  use Sig.Schema

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Organizations.Org

  @primary_key false
  schema "bank_transactions" do
    belongs_to :org, Org, primary_key: true
    belongs_to :financial_transaction, FinancialTransaction, primary_key: true
    belongs_to :bank_account, Account, primary_key: true
  end
end
