defmodule Sig.Finance.FinancialTransactions.FinancialTransactionTest do
  use Sig.DataCase

  alias Sig.Finance.FinancialTransactions.FinancialTransaction

  describe "financial_transactions table constraints" do
    test "`org_id` not_null_violation" do
      transaction = %FinancialTransaction{
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "`org_id` foreign_key_constraint" do
      transaction = %FinancialTransaction{
        org_id: UUID.generate(),
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "`type` not_null_violation" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"type\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "invalid `type`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :invalid,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ChangeError,
                   ~r/\Value `:invalid` is not a valid enum for `Sig.Finance.FinancialTransactions.FinancialTransaction.FinancialTransactionType`/,
                   fn -> Repo.insert(transaction) end
    end

    test "invalid `entry_type`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :cash,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :invalid,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ChangeError,
                   ~r/\Value `:invalid` is not a valid enum for `Sig.EntryType`/,
                   fn -> Repo.insert(transaction) end
    end

    test "missing `placement_date`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"placement_date\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "missing `amount`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        entry_type: :credit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"amount\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "missing `entry_type`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"entry_type\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "missing description" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :debit
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"description\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "`financial_transactions_amount_positive` constraint" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: -1,
        entry_type: :debit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_amount_positive \(check_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "`transfer_counterparty_id` foreign_key_constraint" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence(),
        transfer_counterparty_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_transfer_counterparty_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "success" do
      org = insert(:org)
      counterparty = insert(:financial_transaction, org: org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :credit,
        description: Faker.Lorem.sentence(),
        transfer_counterparty_id: counterparty.id
      }

      assert {:ok, %FinancialTransaction{id: id}} = Repo.insert(transaction)

      assert Repo.get_by(FinancialTransaction,
               id: id,
               org_id: org.id,
               type: transaction.type,
               placement_date: transaction.placement_date,
               clearing_date: transaction.clearing_date,
               amount: transaction.amount,
               entry_type: transaction.entry_type,
               description: transaction.description,
               transfer_counterparty_id: counterparty.id
             )
    end
  end
end
