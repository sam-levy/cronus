defmodule Sig.Finance.FinancialTransactions.FinancialTransactionTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.FinancialTransactions.FinancialTransaction

  describe "financial_transactions table constraints" do
    test "`org_id` not_null_violation" do
      transaction = %FinancialTransaction{
        type: :bank_transfer,
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
        type: :bank_transfer,
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
                   ~r/\Value `:invalid` is not a valid enum for `Sig.Enums.FinancialTransaction.Type`/,
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
        type: :bank_transfer,
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
        type: :bank_transfer,
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
        type: :bank_transfer,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        description: Faker.Lorem.sentence()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"entry_type\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "missing `description`" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank_transfer,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 1,
        entry_type: :debit
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"description\" of relation \"financial_transactions\" violates not-null constraint/,
                   fn -> Repo.insert(transaction) end
    end

    test "`financial_transactions_amount_greater_than_zero` constraint when negative" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank_transfer,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: -1,
        entry_type: :debit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_amount_greater_than_zero \(check_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "`financial_transactions_amount_greater_than_zero` constraint when zero" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank_transfer,
        placement_date: Date.utc_today(),
        clearing_date: Date.utc_today(),
        amount: 0,
        entry_type: :debit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_amount_greater_than_zero \(check_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "`financial_transactions_placement_date_lt_or_eq_clearing_date` constraint" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank_transfer,
        placement_date: ~D[2022-01-02],
        clearing_date: ~D[2022-01-01],
        amount: 1,
        entry_type: :debit,
        description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/financial_transactions_placement_date_lt_or_eq_clearing_date \(check_constraint\)/,
                   fn -> Repo.insert(transaction) end
    end

    test "`transfer_counterparty_id` foreign_key_constraint" do
      org = insert(:org)

      transaction = %FinancialTransaction{
        org_id: org.id,
        type: :bank_transfer,
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
        type: :bank_transfer,
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

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        description: "Description",
        type: :bank_transfer,
        placement_date: ~D[2021-01-01],
        clearing_date: ~D[2021-01-01],
        amount: 100_00,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               clearing_date: attrs[:clearing_date],
               entry_type: attrs[:entry_type],
               placement_date: attrs[:placement_date],
               type: attrs[:type]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: "invalid",
        description: :invalid,
        type: "invalid",
        placement_date: :invalid,
        clearing_date: :invalid,
        amount: :invalid,
        entry_type: "invalid"
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               clearing_date: ["is invalid"],
               description: ["is invalid"],
               placement_date: ["is invalid"],
               type: ["is invalid"],
               amount: ["is invalid"],
               entry_type: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = FinancialTransaction.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"],
               org_id: ["can't be blank"],
               placement_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        description: String.duplicate("a", 256),
        type: :bank_transfer,
        placement_date: ~D[2021-01-01],
        amount: 100_00,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["should be at most 255 character(s)"]
             }
    end

    test "clearing_date before placement_date" do
      attrs = %{
        org_id: UUID.generate(),
        description: "Description",
        type: :bank_transfer,
        placement_date: ~D[2021-01-02],
        clearing_date: ~D[2021-01-01],
        amount: 100_00,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               clearing_date: ["must be after or equal to placement_date"]
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: "Description",
        type: :bank_transfer,
        placement_date: ~D[2021-01-01],
        amount: -1,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than 0,00"]
             }
    end

    test "amount is zero" do
      attrs = %{
        org_id: UUID.generate(),
        description: "Description",
        type: :bank_transfer,
        placement_date: ~D[2021-01-01],
        amount: 0,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than 0,00"]
             }
    end

    test "transfer_counterparty assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        description: "Description",
        type: :bank_transfer,
        placement_date: ~D[2021-01-01],
        clearing_date: ~D[2021-01-01],
        amount: 100_00,
        entry_type: :debit,
        transfer_counterparty_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> FinancialTransaction.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               transfer_counterparty: ["does not exist"]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      financial_transaction =
        insert(:financial_transaction,
          description: "Description",
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-01]
        )

      attrs = %{
        description: "New Description",
        placement_date: ~D[2022-01-01],
        clearing_date: ~D[2022-01-01]
      }

      assert changeset = FinancialTransaction.update_changeset(financial_transaction, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               placement_date: attrs[:placement_date],
               clearing_date: attrs[:clearing_date]
             }
    end

    test "invalid attrs" do
      financial_transaction = insert(:financial_transaction)

      attrs = %{
        description: :invalid,
        placement_date: :invalid,
        clearing_date: :invalid
      }

      assert changeset = FinancialTransaction.update_changeset(financial_transaction, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               clearing_date: ["is invalid"],
               description: ["is invalid"],
               placement_date: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      financial_transaction =
        insert(:financial_transaction,
          description: "Description",
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-01]
        )

      attrs = %{
        org_id: UUID.generate(),
        description: "New Description",
        type: :bank_transfer,
        placement_date: ~D[2022-01-01],
        clearing_date: ~D[2022-01-01],
        amount: 100_00,
        entry_type: :debit
      }

      assert changeset = FinancialTransaction.update_changeset(financial_transaction, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               placement_date: attrs[:placement_date],
               clearing_date: attrs[:clearing_date]
             }
    end

    test "missing required attrs" do
      financial_transaction = insert(:financial_transaction)

      attrs = %{
        description: nil,
        placement_date: nil
      }

      assert changeset = FinancialTransaction.update_changeset(financial_transaction, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["can't be blank"],
               placement_date: ["can't be blank"]
             }
    end

    test "clearing_date before placement_date" do
      financial_transaction =
        insert(:financial_transaction,
          description: "Description",
          placement_date: ~D[2021-01-01],
          clearing_date: ~D[2021-01-01]
        )

      attrs = %{
        description: "New Description",
        placement_date: ~D[2022-01-02],
        clearing_date: ~D[2022-01-01]
      }

      assert changeset = FinancialTransaction.update_changeset(financial_transaction, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               clearing_date: ["must be after or equal to placement_date"]
             }
    end
  end
end
