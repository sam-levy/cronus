defmodule Sig.Finance.Payables.PayablesForPayslipTest do
  use Sig.DataCase

  alias Sig.Accounts.User
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

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

  describe "list_by_payslip/1 for Payslip" do
    test "lists payables from a payslip ordered by due_date" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet,
          org: org,
          target: :payslip,
          due_date: ~D[2021-07-05],
          amount: 100_00
        )

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org =
        insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)

      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      assert [
               %Payable{due_date: ~D[2021-06-20]},
               %Payable{due_date: ~D[2021-07-05]}
             ] = PayablesForPayslip.list_by_payslip(payslip)
    end

    test "preloads" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 200_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)

      assert [
               %Payable{payslip_payable: %PayslipPayable{}}
             ] = PayablesForPayslip.list_by_payslip(payslip)
    end

    test "when payslip has no payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      assert PayablesForPayslip.list_by_payslip(payslip) == []
    end
  end

  describe "get_by_payslip/2" do
    test "returns a payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert %Payable{id: ^id} = PayablesForPayslip.get_by_payslip(payslip, id)
    end

    test "preloads authorized_by" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      %{id: user_id} = user = insert(:user, org: org)

      %{id: payable_id} =
        payable =
        insert(:payable_cash, org: org, target: :payslip, amount: 0, authorized_by: user)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert %Payable{id: ^payable_id, authorized_by: %User{id: ^user_id}} =
               PayablesForPayslip.get_by_payslip(payslip, payable_id)
    end

    test "when payable belongs to another payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      another_payslip = insert(:payslip, org: org, amount: 0)

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: another_payslip, payable: payable)

      assert PayablesForPayslip.get_by_payslip(payslip, id) == nil
    end

    test "when payable doesn't exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)

      assert PayablesForPayslip.get_by_payslip(payslip, UUID.generate()) == nil
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
