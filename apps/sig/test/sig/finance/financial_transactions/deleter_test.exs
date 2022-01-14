defmodule Sig.Finance.FinancialTransactions.DeleterTest do
  use Sig.DataCase

  alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction
  alias Sig.Finance.FinancialTransactions.Deleter
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables.Payable

  describe "delete/1 for cash type" do
    test "deletes a financial transaction" do
      org = insert(:org)
      user = insert(:user, org: org)

      %{id: ft_id} = ft = insert(:financial_transaction, org: org, amount: 100_00)

      %{id: payable_1_id} =
        insert(:payable_cash,
          org: org,
          amount: 50_00,
          financial_transaction: ft,
          authorized_by: user
        )

      %{id: payable_2_id} =
        insert(:payable_cash,
          org: org,
          amount: 50_00,
          financial_transaction: ft,
          authorized_by: user
        )

      assert {:ok, %FinancialTransaction{id: ^ft_id}} = Deleter.call(ft)

      refute Repo.get_by(FinancialTransaction, org_id: org.id, id: ft.id)

      assert payable_1 = Repo.get_by(Payable, org_id: org.id, id: payable_1_id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, org_id: org.id, id: payable_2_id)
      assert payable_2.financial_transaction_id == nil
    end
  end

  describe "delete/1 for bank type" do
    test "deletes a financial transaction" do
      org = insert(:org)
      user = insert(:user, org: org)
      bank_account = insert(:bank_account, org: org)

      %{id: ft_id} = ft = insert(:financial_transaction, type: :bank_transfer, org: org, amount: 100_00)
      insert(:bank_transaction, org: org, bank_account: bank_account, financial_transaction: ft)

      %{id: payable_1_id} =
        insert(:payable_bank_transfer,
          org: org,
          amount: 50_00,
          financial_transaction: ft,
          authorized_by: user
        )

      %{id: payable_2_id} =
        insert(:payable_bank_transfer,
          org: org,
          amount: 50_00,
          financial_transaction: ft,
          authorized_by: user
        )

      assert {:ok, %FinancialTransaction{id: ^ft_id}} = Deleter.call(ft)

      refute Repo.get_by(FinancialTransaction, org_id: org.id, id: ft.id)

      refute Repo.get_by(BankTransaction,
               org_id: org.id,
               bank_account_id: bank_account.id,
               financial_transaction_id: ft.id
             )

      assert payable_1 = Repo.get_by(Payable, org_id: org.id, id: payable_1_id)
      assert payable_1.financial_transaction_id == nil

      assert payable_2 = Repo.get_by(Payable, org_id: org.id, id: payable_2_id)
      assert payable_2.financial_transaction_id == nil
    end
  end
end
