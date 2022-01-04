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
        entry_type: :credit,
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
        financial_transaction_type: :cash
      }

      assert {:error, changeset} = Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert errors_on(changeset) == %{
               amount: ["can't exceed payslip amount"]
             }
    end

    test "ignores the given amount when is auto adjustable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
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
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type],
               amount: 500_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when amount is not given" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 500_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash
      }

      assert {:ok, %Payable{} = return} =
               Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert Repo.get_by(Payable,
               org_id: payslip.org_id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               financial_transaction_type: attrs[:financial_transaction_type],
               amount: 0
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
        entry_type: :credit,
        amount: 800_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 800_00))

      non_adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 400_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: non_adjustable_payable,
          is_auto_adjustable_amount: false
        )

      adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 400_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: adjustable_payable,
          is_auto_adjustable_amount: true
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 500_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash
      }

      assert {:error, changeset} = Create.call(payslip, attrs, is_auto_adjustable_amount: false)

      assert errors_on(changeset) == %{
               amount: ["can't exceed payslip amount"]
             }
    end

    test "new fixed payable amount brings the existing adjustable amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 800_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 800_00))

      non_adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 400_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: non_adjustable_payable,
          is_auto_adjustable_amount: false
        )

      adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 400_00)

      _existing_payslip_payable =
        insert(:payslip_payable,
          org: org,
          payslip: payslip,
          payable: adjustable_payable,
          is_auto_adjustable_amount: true
        )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 400_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: non_adjustable_payable.id, amount: 400_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: adjustable_payable.id, amount: 0_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: adjustable_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "creates a fixed payable when no payable exist" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 100_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type]
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
        entry_type: :credit,
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
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type]
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

    test "creates a fixed payable when adjustable payables exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 900_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 900_00))

      non_adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 200_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: non_adjustable_payable,
        is_auto_adjustable_amount: false
      )

      adjustable_payable = insert(:payable_cash, org: org, target: :payslip, amount: 700_00)

      insert(:payslip_payable,
        org: org,
        payslip: payslip,
        payable: adjustable_payable,
        is_auto_adjustable_amount: true
      )

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        amount: 400_00,
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type]
             )

      assert Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id,
               payable_id: return.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: non_adjustable_payable.id, amount: 200_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: non_adjustable_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable, org_id: org.id, id: adjustable_payable.id, amount: 300_00)

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: adjustable_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "creates an adjustable payable when no payables exist" do
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

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :cash,
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
               financial_transaction_type: attrs[:financial_transaction_type],
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
        entry_type: :credit,
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
        financial_transaction_type: :cash,
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
               financial_transaction_type: attrs[:financial_transaction_type],
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
        entry_type: :credit,
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
        financial_transaction_type: :cash
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
               financial_transaction_type: attrs[:financial_transaction_type],
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

    test "when credit bank account is NOT related to individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      wrong_bank_account = insert(:bank_account, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :bank_transfer,
        credit_bank_account_id: wrong_bank_account.id,
        amount: 100_00
      }

      assert {:error, changeset} = Create.call(payslip, attrs)

      assert errors_on(changeset) == %{
               credit_bank_account_id: ["isn't related to the individual"]
             }
    end

    test "when credit bank account belongs to individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)
      bank_account = insert(:bank_account, org: org, entity: individual.entity)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :bank_transfer,
        credit_bank_account_id: bank_account.id,
        amount: 100_00
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               financial_transaction_type: attrs[:financial_transaction_type],
               credit_bank_account_id: attrs[:credit_bank_account_id],
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id
             )
    end

    test "when credit bank account is associated to individual" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      bank_account = insert(:bank_account, org: org)

      insert(:entity_bank_account, org: org, entity: individual.entity, bank_account: bank_account)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :bank_transfer,
        credit_bank_account_id: bank_account.id,
        amount: 100_00
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               financial_transaction_type: attrs[:financial_transaction_type],
               credit_bank_account_id: attrs[:credit_bank_account_id],
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id
             )
    end

    test "when check bank account is NOT related to company" do
      org = insert(:org)
      company = insert(:company, org: org)
      registration = insert(:employee_registration, org: org, registered_at: company)
      payslip = insert(:payslip, org: org, registration: registration)

      wrong_bank_account = insert(:bank_account, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :check,
        check_number: random_string_number(),
        check_debit_bank_account_id: wrong_bank_account.id,
        amount: 100_00
      }

      assert {:error, changeset} = Create.call(payslip, attrs)

      assert errors_on(changeset) == %{
               check_debit_bank_account_id: ["isn't related to the company"]
             }
    end

    test "when check bank account belongs to company" do
      org = insert(:org)
      company = insert(:company, org: org)
      registration = insert(:employee_registration, org: org, registered_at: company)
      payslip = insert(:payslip, org: org, registration: registration)
      bank_account = insert(:bank_account, org: org, entity: company.entity)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :check,
        check_number: random_string_number(),
        check_debit_bank_account_id: bank_account.id,
        amount: 100_00
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               financial_transaction_type: attrs[:financial_transaction_type],
               check_number: attrs[:check_number],
               check_debit_bank_account_id: attrs[:check_debit_bank_account_id],
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id
             )
    end

    test "when check bank account is associated to company" do
      org = insert(:org)
      company = insert(:company, org: org)
      registration = insert(:employee_registration, org: org, registered_at: company)
      payslip = insert(:payslip, org: org, registration: registration)

      bank_account = insert(:bank_account, org: org)
      insert(:entity_bank_account, org: org, entity: company.entity, bank_account: bank_account)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 100_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      attrs = %{
        due_date: Date.utc_today(),
        reference_date: Date.utc_today() |> Date.beginning_of_month(),
        description: Faker.Lorem.sentence(),
        note: Faker.Lorem.sentence(),
        financial_transaction_type: :check,
        check_number: random_string_number(),
        check_debit_bank_account_id: bank_account.id,
        amount: 100_00
      }

      assert {:ok, %Payable{} = return} = Create.call(payslip, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: return.id,
               target: :payslip,
               due_date: attrs[:due_date],
               reference_date: attrs[:reference_date],
               description: attrs[:description],
               note: attrs[:note],
               financial_transaction_type: attrs[:financial_transaction_type],
               check_number: attrs[:check_number],
               check_debit_bank_account_id: attrs[:check_debit_bank_account_id],
               amount: 100_00
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: return.id
             )
    end

    test "returns changeset errors" do
      payslip = insert(:payslip)

      assert {:error, changeset} = Create.call(payslip, %{})

      assert errors_on(changeset) == %{
               due_date: ["can't be blank"]
             }

      refute Repo.get_by(Payable, org_id: payslip.org_id)

      refute Repo.get_by(PayslipPayable,
               org_id: payslip.org_id,
               payslip_id: payslip.id
             )
    end
  end
end
