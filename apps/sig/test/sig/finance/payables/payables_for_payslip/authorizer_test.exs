defmodule Sig.Finance.Payables.PayablesForPayslip.AuthorizerTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.Authorizer
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "authorize/2" do
    test "assign an authorized_by_id to a payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      %{id: id} = payable = insert(:payable_cash, org: org, payslip: payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      user = insert(:user, org: org)

      assert {:ok, %Payable{id: ^id}} = Authorizer.authorize(payslip, payable, user)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: id,
               authorized_by_id: user.id
             )
    end

    test "unsets payslip payable auto adjustable amount" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      %{id: id} = payable = insert(:payable_cash, org: org, payslip: payslip, amount: 0)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: true
      )

      user = insert(:user, org: org)

      assert {:ok, %Payable{id: ^id}} = Authorizer.authorize(payslip, payable, user)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: id,
               authorized_by_id: user.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when payable is already authorized" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      user = insert(:user, org: org)

      %{id: id} =
        payable =
        insert(:payable_cash, org: org, payslip: payslip, amount: 0, authorized_by_id: user.id)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      another_user = insert(:user, org: org)

      assert Authorizer.authorize(payslip, payable, another_user) ==
               {:error, "can't modify an authorized payable"}

      assert Repo.get_by(Payable,
               id: id,
               org_id: org.id,
               authorized_by_id: user.id
             )
    end
  end

  describe "unauthorize/2" do
    test "removes a authorized_by_id from a payable" do
      org = insert(:org)
      user = insert(:user, org: org)
      %{id: id} = payable = insert(:payable_cash, org: org, authorized_by_id: user.id)

      assert {:ok, %Payable{id: ^id}} = Authorizer.unauthorize(payable)

      assert persisted_payable = Repo.get_by(Payable, id: id, org_id: org.id)

      assert persisted_payable.authorized_by_id == nil
    end

    test "when payable is fulfilled" do
      org = insert(:org)
      user = insert(:user, org: org)
      financial_transaction = insert(:financial_transaction, org: org)

      %{id: id} =
        payable =
        insert(:payable_cash,
          org: org,
          authorized_by: user,
          financial_transaction: financial_transaction
        )

      assert Authorizer.unauthorize(payable) ==
               {:error, "can't modify a fulfilled payable"}

      assert Repo.get_by(Payable,
               id: id,
               org_id: org.id,
               authorized_by_id: user.id,
               financial_transaction_id: financial_transaction.id
             )
    end

    test "when authorized_by_id is already nil" do
      %{id: id} = payable = insert(:payable_cash, authorized_by_id: nil)

      assert {:ok, %Payable{id: ^id}} = Authorizer.unauthorize(payable)

      assert persisted_payable = Repo.get_by(Payable, id: id, org_id: payable.org_id)

      assert persisted_payable.authorized_by_id == nil
    end
  end
end
