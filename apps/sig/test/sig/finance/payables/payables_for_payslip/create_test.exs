defmodule Sig.Finance.Payables.PayablesForPayslip.CreateTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.PayablesForPayslip.Create
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "create/2 for Payslip" do
    test "amount can't exceed the payslip amount when not auto adjustable" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 600_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:error, changeset} = Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert errors_on(changeset) == %{
        amount: ["can't exceed payslip amount"]
      }
    end

    test "when amount is not given" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert Repo.get_by(Payable,
               org_id: payslip.org_id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               amount: 0,
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )
    end

    test "sum of payable amounts can't exceed the payslip amount when fixed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 800_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 800_00))

      existing_payable = insert(:payable_cash, org: org, target: :payslip, amount: 400_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable,
          is_auto_adjustable_amount: false
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 500_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:error, changeset} = Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert errors_on(changeset) == %{
        amount: ["can't exceed payslip amount"]
      }
    end

    test "creates a fixed payable when no payable exist" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 100_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: payslip.org_id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )
    end

    test "creates a fixed payable when fixed payables exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 900_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      existing_payable_1 = insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      _existing_payslip_payable_1 =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable_1,
          is_auto_adjustable_amount: false
        )

      existing_payable_2 = insert(:payable_cash, org: org, target: :payslip, amount: 300_00)

      _existing_payslip_payable_2 =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable_2,
          is_auto_adjustable_amount: false
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 400_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: payslip.org_id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               amount: attrs[:amount],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )

      # existing_payable_1
      assert Repo.get_by(Payable, org_id: org.id, id: existing_payable_1.id, amount: 200_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: existing_payable_1.id,
               is_auto_adjustable_amount: false
             )

      # existing_payable_2
      assert Repo.get_by(Payable, org_id: org.id, id: existing_payable_2.id, amount: 300_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: existing_payable_2.id,
               is_auto_adjustable_amount: false
             )
    end

    test "creates an adjustable payable when no payables exist" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash,
        # Amount should be ignored when auto adjustable
        amount: 1_000_00
      }

      assert {:ok, %Payable{} = return} =
               Create.call(payslip, attrs, is_auto_adjustable_amount: true)

      assert Repo.get_by(Payable,
               org_id: payslip.org_id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: true
             )
    end

    test "creates an adjustable payable when adjustable payable exist" do
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

      existing_payable = insert(:payable_cash, org: org, target: :payslip, amount: 500_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable,
          is_auto_adjustable_amount: true
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash,
        # Amount should be ignored when auto adjustable
        amount: 1_000_00
      }

      assert {:ok, %Payable{} = return} =
               Create.call(payslip, attrs, is_auto_adjustable_amount: true)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               amount: 0
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: true
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: existing_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "creates an adjustable payable when fixed payables exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 600_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      existing_payable = insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: existing_payable,
          is_auto_adjustable_amount: false
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        method: :cash
      }

      assert {:ok, %Payable{} = return} =
               Create.call(payslip, attrs, is_auto_adjustable_amount: true)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               method: attrs[:method],
               amount: 400_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: true
             )

      # existing_payable
      assert Repo.get_by(Payable, org_id: org.id, id: existing_payable.id, amount: 200_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: existing_payable.id,
               is_auto_adjustable_amount: false
             )
    end

    test "returns changeset errors" do
      payslip = insert(:payslip)

      assert {:error, changeset} = Create.call(payslip, %{})

      assert errors_on(changeset) == %{
               due_date: ["can't be blank"],
               reference_date: ["can't be blank"]
             }

      refute Repo.get_by(Payable, org_id: payslip.org_id)

      refute Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id
             )
    end
  end
end
