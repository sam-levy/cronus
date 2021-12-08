defmodule Sig.Finance.Payables.DeleteByIdsTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.DeleteByIds
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "call/1" do
    test "deletes payables and payslip_payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      Repo.update!(change(payslip, amount: 200_00))

      payables = insert_list(2, :payable_cash, org: org, amount: 100_00)

      Enum.each(payables, fn payable ->
        insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
      end)

      payable_ids = Enum.map(payables, & &1.id)

      assert {:ok, [%Payable{}, %Payable{}]} = DeleteByIds.call(org, payable_ids)

      Enum.each(payables, fn payable ->
        refute Repo.get_by(Payable, org_id: org.id, id: payable.id)
        refute Repo.get_by(PayslipPayable, org_id: org.id, payable_id: payable.id)
      end)
    end

    test "when payable is authorized" do
      org = insert(:org)
      user = insert(:user, org: org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      Repo.update!(change(payslip, amount: 200_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      authorized_payable =
        insert(:payable_cash, org: org, amount: 100_00, is_fulfilled: false, authorized_by: user)

      Enum.each([payable, authorized_payable], fn payable ->
        insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
      end)

      payable_ids = [payable.id, authorized_payable.id]

      assert DeleteByIds.call(org, payable_ids) ==
               {:error, "existem pagamentos autorizados ou pagos"}

      Enum.each([payable, authorized_payable], fn payable ->
        assert Repo.get_by(Payable, org_id: org.id, id: payable.id)
        assert Repo.get_by(PayslipPayable, org_id: org.id, payable_id: payable.id)
      end)
    end

    test "when payable is fulfilled" do
      org = insert(:org)
      user = insert(:user, org: org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      Repo.update!(change(payslip, amount: 200_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      fulfilled_payable =
        insert(:payable_cash, org: org, amount: 100_00, is_fulfilled: true, authorized_by: user)

      Enum.each([payable, fulfilled_payable], fn payable ->
        insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
      end)

      payable_ids = [payable.id, fulfilled_payable.id]

      assert DeleteByIds.call(org, payable_ids) ==
               {:error, "existem pagamentos autorizados ou pagos"}

      Enum.each([payable, fulfilled_payable], fn payable ->
        assert Repo.get_by(Payable, org_id: org.id, id: payable.id)
        assert Repo.get_by(PayslipPayable, org_id: org.id, payable_id: payable.id)
      end)
    end

    test "when id list is empty" do
      org = insert(:org)

      assert DeleteByIds.call(org, []) == {:ok, nil}
    end
  end
end
