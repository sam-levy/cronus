defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayablesTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "set_as_auto_adjustable_amount/2" do
    test "sets is auto adjustable amount when there is no other payslip_payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
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
               PayslipPayables.set_as_auto_adjustable_amount(payslip, payable)

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
        entry_type: :credit,
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
               PayslipPayables.set_as_auto_adjustable_amount(
                 payslip,
                 non_adjustable_payable
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

    test "when is auto adjustable amount is already true" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: true
      )

      assert {:ok, %PayslipPayable{is_auto_adjustable_amount: true}} =
               PayslipPayables.set_as_auto_adjustable_amount(payslip, payable)

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when payable is fulfilled" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

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

      assert PayslipPayables.set_as_auto_adjustable_amount(payslip, payable) ==
               {:error, "can't modify a fulfilled payable"}

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
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

      assert PayslipPayables.set_as_auto_adjustable_amount(
               another_payslip,
               payable
             ) ==
               {:error, :not_found}

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end
  end

  describe "unset_as_auto_adjustable_amount/2" do
    test "unsets is auto adjustable amount" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, amount: 100_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: true
      )

      assert {:ok, %PayslipPayable{}} =
               PayslipPayables.unset_as_auto_adjustable_amount(payslip, payable)

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when is auto adjustable amount is already false" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
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

      assert {:ok, %PayslipPayable{}} =
               PayslipPayables.unset_as_auto_adjustable_amount(payslip, payable)

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when payable is fulfilled" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

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
        is_auto_adjustable_amount: true
      )

      assert PayslipPayables.unset_as_auto_adjustable_amount(payslip, payable) ==
               {:error, "can't modify a fulfilled payable"}

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: true
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
        is_auto_adjustable_amount: true
      )

      another_payslip = insert(:payslip, org: org, amount: 0)

      assert PayslipPayables.unset_as_auto_adjustable_amount(
               another_payslip,
               payable
             ) ==
               {:error, :not_found}

      assert Repo.get_by!(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payable.id,
               is_auto_adjustable_amount: true
             )
    end
  end
end
