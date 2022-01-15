defmodule Sig.Finance.Payables.PayablesForPayslipTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.update_change(%Payable{}, %{})
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.update_change(%Payable{})
    end
  end

  describe "sum_non_adjustable_payables_amounts/1" do
    test "sums the amounts of the non adjustable payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 1_000_00
      )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 400_00,
        is_payment_advance: true
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      salary_advance_payable_1 =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable_1,
        is_auto_adjustable_amount: false
      )

      salary_advance_payable_2 =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable_2,
        is_auto_adjustable_amount: false
      )

      salary_payable = insert(:payable_bank_transfer, target: :payslip, org: org, amount: 600_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_payable,
        is_auto_adjustable_amount: true
      )

      ###### TO BE IGNORED ######
      payslip_to_ignore = insert(:payslip, org: org, registration: payslip.registration)

      payable_to_ignore = insert(:payable_cash, target: :payslip, org: org, amount: 300_00)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_to_ignore,
        entry_type: :credit,
        amount: 300_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_to_ignore,
        entry_type: :debit,
        amount: 100_00,
        is_payment_advance: true
      )

      Repo.update!(change(payslip_to_ignore, amount: 200_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip_to_ignore,
        payable: payable_to_ignore,
        is_auto_adjustable_amount: false
      )

      #######################

      assert PayablesForPayslip.sum_non_adjustable_payables_amounts(payslip) == %Money{
               amount: 400_00,
               currency: :BRL
             }
    end
  end

  describe "sum_non_adjustable_payables_amounts/2" do
    test "sums the amounts of the non adjustable payables ignoring the passed payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 1_000_00
      )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        entry_type: :debit,
        amount: 400_00,
        is_payment_advance: true
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      salary_advance_payable_1 =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable_1,
        is_auto_adjustable_amount: false
      )

      salary_advance_payable_2 =
        insert(:payable_bank_transfer, target: :payslip, org: org, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_advance_payable_2,
        is_auto_adjustable_amount: false
      )

      salary_payable = insert(:payable_bank_transfer, target: :payslip, org: org, amount: 600_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: salary_payable,
        is_auto_adjustable_amount: true
      )

      ###### TO BE IGNORED ######
      payslip_to_ignore = insert(:payslip, org: org, registration: payslip.registration)

      payable_to_ignore = insert(:payable_cash, target: :payslip, org: org, amount: 300_00)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_to_ignore,
        entry_type: :credit,
        amount: 300_00
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip_to_ignore,
        entry_type: :debit,
        amount: 100_00,
        is_payment_advance: true
      )

      Repo.update!(change(payslip_to_ignore, amount: 200_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip_to_ignore,
        payable: payable_to_ignore,
        is_auto_adjustable_amount: false
      )

      #######################

      assert PayablesForPayslip.sum_non_adjustable_payables_amounts(
               payslip,
               salary_advance_payable_1
             ) == %Money{
               amount: 200_00,
               currency: :BRL
             }
    end
  end
end
