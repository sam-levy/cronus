defmodule Sig.Finance.FinancialTransactionsTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.FinancialTransactions
  alias Sig.Finance.FinancialTransactions.FinancialTransaction

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %FinancialTransaction{}} =
               FinancialTransactions.update_change(%FinancialTransaction{}, %{})

      assert %Ecto.Changeset{data: %FinancialTransaction{}} =
               FinancialTransactions.update_change(%FinancialTransaction{})
    end
  end

  describe "clear/2" do
    test "sets a financial transaction clearing_date" do
      financial_transaction =
        insert(:financial_transaction, placement_date: ~D[2022-01-01], clearing_date: nil)

      attrs = %{clearing_date: ~D[2022-01-01]}

      assert {:ok, %FinancialTransaction{clearing_date: ~D[2022-01-01]}} =
               FinancialTransactions.clear(financial_transaction, attrs)
    end

    test "when clearing date is already set" do
      financial_transaction =
        insert(:financial_transaction,
          placement_date: ~D[2022-01-01],
          clearing_date: ~D[2022-01-01]
        )

      attrs = %{clearing_date: ~D[2022-01-01]}

      assert {:error, "already cleared"} =
               FinancialTransactions.clear(financial_transaction, attrs)
    end

    test "returns changeset errors" do
      financial_transaction =
        insert(:financial_transaction, placement_date: ~D[2022-01-02], clearing_date: nil)

      attrs = %{clearing_date: ~D[2022-01-01]}

      assert {:error, changeset} = FinancialTransactions.clear(financial_transaction, attrs)

      assert errors_on(changeset) == %{
               clearing_date: ["must be after or equal to placement_date"]
             }
    end
  end

  describe "list_by/2 Org" do
    test "lists financial transactions by org ordered by `clearing_date` and `description`" do
      org = insert(:org)

      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-02], description: "B")
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-02], description: "A")
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-01], description: "B")
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-01], description: "A")
      _to_ignore = insert(:financial_transaction, clearing_date: ~D[2022-01-01], description: "A")

      assert [
               %FinancialTransaction{clearing_date: ~D[2022-01-01], description: "A"},
               %FinancialTransaction{clearing_date: ~D[2022-01-01], description: "B"},
               %FinancialTransaction{clearing_date: ~D[2022-01-02], description: "A"},
               %FinancialTransaction{clearing_date: ~D[2022-01-02], description: "B"}
             ] = FinancialTransactions.list_by(org)
    end

    test "lists financial transactions filtered by `clearing_date` period" do
      org = insert(:org)

      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-01])
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-02])
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-03])
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-04])
      insert(:financial_transaction, org: org, clearing_date: ~D[2022-01-05])

      assert [
               %FinancialTransaction{clearing_date: ~D[2022-01-02]},
               %FinancialTransaction{clearing_date: ~D[2022-01-03]},
               %FinancialTransaction{clearing_date: ~D[2022-01-04]}
             ] =
               FinancialTransactions.list_by(org,
                 clearing_date: [period_start: ~D[2022-01-02], period_end: ~D[2022-01-04]]
               )
    end

    test "lists financial transactions filtered by `placement_date` period when `clearing_date` is `nil`" do
      org = insert(:org)

      insert(:financial_transaction,
        org: org,
        placement_date: ~D[2022-01-01],
        clearing_date: nil,
        description: "A"
      )

      insert(:financial_transaction,
        org: org,
        placement_date: ~D[2022-01-02],
        clearing_date: nil,
        description: "B"
      )

      insert(:financial_transaction,
        org: org,
        placement_date: ~D[2022-01-03],
        clearing_date: nil,
        description: "C"
      )

      insert(:financial_transaction,
        org: org,
        placement_date: ~D[2022-01-04],
        clearing_date: nil,
        description: "D"
      )

      insert(:financial_transaction,
        org: org,
        placement_date: ~D[2022-01-05],
        clearing_date: nil,
        description: "E"
      )

      assert [
               %FinancialTransaction{placement_date: ~D[2022-01-01]},
               %FinancialTransaction{placement_date: ~D[2022-01-02]},
               %FinancialTransaction{placement_date: ~D[2022-01-03]},
               %FinancialTransaction{placement_date: ~D[2022-01-04]}
             ] =
               FinancialTransactions.list_by(org,
                 clearing_date: [period_start: ~D[2022-01-02], period_end: ~D[2022-01-04]]
               )
    end

    test "preloads" do
      org = insert(:org)
      bank_account = insert(:bank_account, org: org)

      financial_transaction = insert(:financial_transaction, org: org)

      insert(:bank_transaction,
        org: org,
        bank_account: bank_account,
        financial_transaction: financial_transaction
      )

      assert [
               %FinancialTransaction{bank_account: %Account{}}
             ] = FinancialTransactions.list_by(org, preload: [:bank_account])
    end
  end
end
