defmodule Sig.Finance.FinancialTransactions.FinancialTransactionTest do
  use Sig.DataCase

  alias Sig.Finance.FinancialTransactions.FinancialTransaction

  describe "financial_transactions table constraints" do
    test "org_id not_null_violation" do
      transaction = %FinancialTransaction{
        type: :bank
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "org_id foreign_key_constraint" do
      transaction = %FinancialTransaction{
        org_id: UUID.generate(),
        type: :bank
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "type not_null_violation" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"type\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "invalid type" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :invalid
      }

      assert_raise Ecto.ChangeError,
                   ~r/\Value `:invalid` is not a valid enum for `Sig.Finance.FinancialTransactions.FinancialTransaction.FinancialTransactionType`/,
                   fn -> Repo.insert(transaction) end
    end

    test "valid attrs" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :cash
      }

      assert {:ok, transaction} = Repo.insert(transaction)

      assert Repo.get_by(FinancialTransaction,
               id: transaction.id,
               org_id: org.id,
               type: :cash
             )
    end
  end
end
