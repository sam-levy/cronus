defmodule Sig.Finance.FinancialTransactionsTest do
  use Sig.DataCase

  alias Sig.Finance.FinancialTransactions
  alias Sig.Finance.FinancialTransactions.FinancialTransaction

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
  end
end
