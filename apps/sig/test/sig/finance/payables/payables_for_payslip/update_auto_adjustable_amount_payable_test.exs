defmodule Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayableTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "call/2 for Payslip" do
    test "updates the auto adjustable payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      %{id: id} =
        auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: auto_adjustable_payable,
        is_auto_adjustable_amount: true
      )

      non_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_auto_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %Payable{id: ^id}} = UpdateAutoAdjustableAmountPayable.call(payslip)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: auto_adjustable_payable.id,
               amount: 400_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: auto_adjustable_payable.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_auto_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_auto_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when there is no auto adjustable payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      non_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_auto_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      assert UpdateAutoAdjustableAmountPayable.call(payslip) == {:ok, nil}

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_auto_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_auto_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when there is no payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      assert UpdateAutoAdjustableAmountPayable.call(payslip) == {:ok, nil}
    end

    test "when the auto adjustable payable is fulfilled" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      user = insert(:user, org: org)

      auto_adjustable_payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          amount: 200_00,
          is_fulfilled: true,
          authorized_by: user
        )

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: auto_adjustable_payable,
        is_auto_adjustable_amount: true
      )

      non_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_auto_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      assert UpdateAutoAdjustableAmountPayable.call(payslip) == {:ok, nil}

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: auto_adjustable_payable.id,
               amount: 200_00,
               is_fulfilled: true,
               authorized_by_id: user.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: auto_adjustable_payable.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_auto_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_auto_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when subtract opts is present" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      %{id: id} =
        auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: auto_adjustable_payable,
        is_auto_adjustable_amount: true
      )

      non_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_auto_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %Payable{id: ^id}} =
               UpdateAutoAdjustableAmountPayable.call(payslip, subtract: 100_00)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: auto_adjustable_payable.id,
               amount: 300_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: auto_adjustable_payable.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_auto_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_auto_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end
  end
end
