defmodule Sig.Finance.Payables.PayablesForPayslip.AutoAdjustableAmountHandlerTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Finance.Payables.PayablesForPayslip.AutoAdjustableAmountHandler

  describe "update/3 for Payslip" do
    test "set as auto adjustable and update payable amount" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 400_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 400_00))

      non_adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      prior_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: prior_auto_adjustable_payable,
        is_auto_adjustable_amount: true
      )

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %Payable{id: ^id}} =
               AutoAdjustableAmountHandler.set_as_auto_adjustable_amount(payslip, payable)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payable.id,
               amount: 200_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: prior_auto_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: prior_auto_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when payable is fulfilled" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      user = insert(:user, org: org)

      payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          amount: 100_00,
          is_fulfilled: true,
          authorized_by_id: user.id
        )

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      assert AutoAdjustableAmountHandler.set_as_auto_adjustable_amount(payslip, payable) ==
               {:error, "can't modify a fulfilled payable"}

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payable.id,
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end
  end
end
