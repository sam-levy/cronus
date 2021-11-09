defmodule Sig.Finance.Payables.PayablesForPayslip.UpdateTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.PayablesForPayslip.Update
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "update/3 for Payslip" do
    test "updates a payable" do
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

      %{id: id} =
        payable = insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:ok, %Payable{id: ^id} = return} = Update.call(payslip, payable, attrs)

      assert Repo.get_by(Payable,
               org_id: return.org_id,
               id: id,
               target: payable.target,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             )
    end

    test "decreases an auto adjustable payable amount when a fixed payable amount is increased" do
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
        payable = insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: Money.new(400_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: adjustable_payable,
        is_auto_adjustable_amount: true
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 300_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:ok, %Payable{id: ^id} = return} = Update.call(payslip, payable, attrs)

      assert Repo.get_by(Payable,
               org_id: return.org_id,
               id: id,
               target: payable.target,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: adjustable_payable.id, amount: 200_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: adjustable_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "increases an auto adjustable payable amount when a fixed payable amount is decreased" do
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
        payable = insert(:payable_cash, org: org, target: :payslip, amount: Money.new(200_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: Money.new(300_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: adjustable_payable,
        is_auto_adjustable_amount: true
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 100_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:ok, %Payable{id: ^id} = return} = Update.call(payslip, payable, attrs)

      assert Repo.get_by(Payable,
               org_id: return.org_id,
               id: id,
               target: payable.target,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: adjustable_payable.id, amount: 400_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: adjustable_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when payable is fulfilled" do
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

      user = insert(:user, org: org)

      payable =
        insert(:payable_cash,
          org: org,
          target: :payslip,
          amount: Money.new(100_00),
          is_fulfilled: true,
          authorized_by_id: user.id
        )

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:error, changeset} = Update.call(payslip, payable, attrs)

      assert errors_on(changeset) == %{
               amount: ["can't be changed when payable is fulfilled"]
             }
    end

    test "amount can't exceed the payslip amount when not auto adjustable" do
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

      non_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      %{id: id} =
        payable = insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 200_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:error, changeset} = Update.call(payslip, payable, attrs)

      assert errors_on(changeset) == %{
               amount: ["can't exceed payslip amount"]
             }

      refute Repo.get_by(Payable,
               org_id: org.id,
               id: id,
               target: payable.target,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode]
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_adjustable_payable.id,
               amount: 100_00
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payable.id,
               amount: 100_00
             )
    end

    test "adjusts existing adjustable payable" do
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

      non_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      auto_adjustable_payable =
        insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: auto_adjustable_payable,
        is_auto_adjustable_amount: true
      )

      %{id: id} =
        payable = insert(:payable_cash, org: org, target: :payslip, amount: Money.new(100_00))

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: payable,
        is_auto_adjustable_amount: false
      )

      attrs = %{
        due_date: ~D[2021-01-15],
        reference_date: ~D[2021-01-01],
        amount: 50_00,
        description: "Updated description",
        note: "Updated note",
        method: :billet,
        billet_barcode: random_string_number()
      }

      assert {:ok, %Payable{id: ^id}} = Update.call(payslip, payable, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: id,
               target: payable.target,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               billet_barcode: attrs[:billet_barcode],
               amount: attrs[:amount]
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: auto_adjustable_payable.id,
               amount: 150_00
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: non_adjustable_payable.id,
               amount: 100_00
             )
    end
  end
end
