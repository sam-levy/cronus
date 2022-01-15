defmodule Sig.Finance.FinancialTransactions.BankTransactions.BankTransactionTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction

  describe "bank_transactions table constraints" do
    test "`org_id` not_null_violation" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)
      bank_account = insert(:bank_account, org: org)

      bank_transaction = %BankTransaction{
        financial_transaction_id: financial_transaction.id,
        bank_account_id: bank_account.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"bank_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "`org_id` foreign_key_constraint" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)
      bank_account = insert(:bank_account, org: org)

      bank_transaction = %BankTransaction{
        org_id: UUID.generate(),
        financial_transaction_id: financial_transaction.id,
        bank_account_id: bank_account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_transactions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "`financial_transaction_id` not_null_violation" do
      org = insert(:org)
      bank_account = insert(:bank_account, org: org)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        bank_account_id: bank_account.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"financial_transaction_id\" of relation \"bank_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "`financial_transaction_id` foreign_key_constraint" do
      org = insert(:org)
      bank_account = insert(:bank_account, org: org)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        financial_transaction_id: UUID.generate(),
        bank_account_id: bank_account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_transactions_financial_transaction_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "`bank_account_id` not_null_violation" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        financial_transaction_id: financial_transaction.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"bank_account_id\" of relation \"bank_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "`bank_account_id` foreign_key_constraint" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        financial_transaction_id: financial_transaction.id,
        bank_account_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_transactions_bank_account_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "bank_transactions_financial_transaction_unique unique_index" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)
      bank_account = insert(:bank_account, org: org)

      _existing_bank_transaction =
        insert(:bank_transaction, org: org, financial_transaction: financial_transaction)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        financial_transaction_id: financial_transaction.id,
        bank_account_id: bank_account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_transactions_financial_transaction_unique \(unique_constraint\)/,
                   fn -> Repo.insert(bank_transaction) end
    end

    test "success" do
      org = insert(:org)
      financial_transaction = insert(:financial_transaction, org: org)
      bank_account = insert(:bank_account, org: org)

      bank_transaction = %BankTransaction{
        org_id: org.id,
        financial_transaction_id: financial_transaction.id,
        bank_account_id: bank_account.id
      }

      assert {:ok, %BankTransaction{}} = Repo.insert(bank_transaction)

      assert Repo.get_by(BankTransaction,
               org_id: org.id,
               financial_transaction_id: financial_transaction.id,
               bank_account_id: bank_account.id
             )
    end
  end
end
