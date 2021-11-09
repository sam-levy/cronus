defmodule Sig.Finance.Payables.PayablesForPayslip.DeleteTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.Delete
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "delete/1" do
    test "deletes a payable and its payslip_payable" do
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

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 100_00)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert {:ok, %Payable{id: ^id}} = Delete.call(payslip, payable)

      refute Repo.get_by(Payable, org_id: org.id, id: id)

      refute Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: payable.id
             )
    end

    test "updates existing auto adjustable amount payable" do
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

      existing_auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 300_00)

      _existing_auto_adjustable_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_auto_adjustable_payable,
          is_auto_adjustable_amount: true
        )

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %Payable{id: ^id}} = Delete.call(payslip, payable)

      refute Repo.get_by(Payable, org_id: org.id, id: id)

      refute Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: payable.id
             )

      # Updates existing auto adjustable amount payable
      assert Repo.get_by(Payable,
               org_id: org.id,
               id: existing_auto_adjustable_payable.id,
               amount: 500_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: existing_auto_adjustable_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when existing payable is not auto adjustable" do
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

      existing_payable = insert(:payable_cash, org: org, target: :payslip, amount: 300_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable,
          is_auto_adjustable_amount: false
        )

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      assert {:ok, %Payable{id: ^id}} = Delete.call(payslip, payable)

      refute Repo.get_by(Payable, org_id: org.id, id: id)

      refute Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: payable.id
             )

      # Don't update the existing payable amount
      assert Repo.get_by(Payable,
               org_id: org.id,
               id: existing_payable.id,
               amount: 300_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: existing_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when payable is_fulfilled" do
      org = insert(:org)
      user = insert(:user, org: org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      %{id: id} =
        payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          amount: 100_00,
          is_fulfilled: true,
          authorized_by_id: user.id
        )

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert {:error, "cannot delete a fulfilled payable"} = Delete.call(payslip, payable)

      assert Repo.get_by(Payable, org_id: org.id, id: id)

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: payable.id
             )
    end
  end
end
