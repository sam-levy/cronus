defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayablesTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "set_is_auto_adjustable_amount/2" do
    test "sets is auto adjustable amount when there is no other payslip_payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %PayslipPayable{is_auto_adjustable_amount: true}} =
               PayslipPayables.set_is_auto_adjustable_amount(payslip, payable.id)

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "sets is auto adjustable amount when there are other ajustable payslip_payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 300_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 300_00))

      adjustable_payable = insert(:payable_cash, org: org, amount: 100_00)
      non_adjustable_payable = insert(:payable_cash, org: org, amount: 100_00)
      another_non_adjustable_payable = insert(:payable_cash, org: org, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: adjustable_payable,
        is_auto_adjustable_amount: true
      )

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: another_non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %PayslipPayable{is_auto_adjustable_amount: true}} =
               PayslipPayables.set_is_auto_adjustable_amount(
                 payslip,
                 non_adjustable_payable.id
               )

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_adjustable_payable.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: adjustable_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: another_non_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when payable is from a different payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      payable = insert(:payable_cash, org: org, amount: 0)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      another_payslip = insert(:payslip, org: org, amount: 0)

      assert PayslipPayables.set_is_auto_adjustable_amount(another_payslip, payable.id) ==
               {:error, :not_found}

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end
  end
end
