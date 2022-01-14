defmodule Sig.Finance.Payables.PayablesForPayslip.CreateStandardPayablesTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Finance.Payables.PayablesForPayslip.CreateStandardPayables

  describe "call/4" do
    test "creates payment advance and salary payables" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      bank_account = insert(:bank_account, org: org, entity: individual.entity, is_primary: true)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(100_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: payment_advance_payable, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, items, due_dates)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payment_advance_payable.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 400_00,
               due_date: ~D[2021-01-20],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :bank_transfer,
               credit_bank_account_id: bank_account.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payment_advance_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: salary_payable.id,
               target: :payslip,
               description: "Salário",
               amount: 500_00,
               due_date: ~D[2021-02-05],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :bank_transfer,
               credit_bank_account_id: bank_account.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when there is no is_payment_advance payslip item" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      bank_account = insert(:bank_account, org: org, entity: individual.entity, is_primary: true)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: false
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: nil, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, items, due_dates)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: salary_payable.id,
               target: :payslip,
               description: "Salário",
               amount: 600_00,
               due_date: ~D[2021-02-05],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :bank_transfer,
               credit_bank_account_id: bank_account.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Adiantamento de Salário"
             )

      refute Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               is_auto_adjustable_amount: false
             )
    end

    test "when there is more than one is_payment_advance payslip item" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      bank_account = insert(:bank_account, org: org, entity: individual.entity, is_primary: true)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(2_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 1_200_00))

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: payment_advance_payable, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, items, due_dates)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payment_advance_payable.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 800_00,
               due_date: ~D[2021-01-20],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :bank_transfer,
               credit_bank_account_id: bank_account.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payment_advance_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: salary_payable.id,
               target: :payslip,
               description: "Salário",
               amount: 1_200_00,
               due_date: ~D[2021-02-05],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :bank_transfer,
               credit_bank_account_id: bank_account.id
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when individual has no bank account" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: payment_advance_payable, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, items, due_dates)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: payment_advance_payable.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 400_00,
               due_date: ~D[2021-01-20],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :cash
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payment_advance_payable.id,
               is_auto_adjustable_amount: false
             )

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: salary_payable.id,
               target: :payslip,
               description: "Salário",
               amount: 600_00,
               due_date: ~D[2021-02-05],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :cash
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "creates cash payables when individual primary bank account is inactive" do
      org = insert(:org)
      individual = insert(:individual, org: org)

      insert(:bank_account,
        org: org,
        entity: individual.entity,
        is_primary: true,
        is_active: false
      )

      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(100_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 500_00))

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: payment_advance_payable, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, items, due_dates)

      assert %Payable{credit_bank_account_id: nil} =
               Repo.get_by(Payable,
                 org_id: org.id,
                 id: payment_advance_payable.id,
                 target: :payslip,
                 description: "Adiantamento de Salário",
                 amount: 400_00,
                 due_date: ~D[2021-01-20],
                 reference_date: Date.beginning_of_month(payslip.start_date),
                 financial_transaction_type: :cash
               )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payment_advance_payable.id,
               is_auto_adjustable_amount: false
             )

      assert %Payable{credit_bank_account_id: nil} =
               Repo.get_by(Payable,
                 org_id: org.id,
                 id: salary_payable.id,
                 target: :payslip,
                 description: "Salário",
                 amount: 500_00,
                 due_date: ~D[2021-02-05],
                 reference_date: Date.beginning_of_month(payslip.start_date),
                 financial_transaction_type: :cash
               )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when payslip has no items" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert {:ok, %{payment_advance: nil, salary: salary_payable}} =
               CreateStandardPayables.call(registration, payslip, [], due_dates)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: salary_payable.id,
               target: :payslip,
               description: "Salário",
               amount: 0,
               due_date: ~D[2021-02-05],
               reference_date: Date.beginning_of_month(payslip.start_date),
               financial_transaction_type: :cash
             )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "when items doesn't belong to payslip" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}

      assert CreateStandardPayables.call(registration, payslip, items, due_dates) ==
               {:error, "payslip items doesn't belong to payslip"}

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 400_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Salário",
               amount: 600_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)
    end

    test "wrong due_dates keys" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      due_dates = %{wrong_date: ~D[2021-01-20], anotther_wrong_date: ~D[2021-02-05]}

      assert CreateStandardPayables.call(registration, payslip, items, due_dates) ==
               {:error, "invalid payments due dates"}

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 400_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Salário",
               amount: 600_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)
    end

    test "wrong due_dates values" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      registration = insert(:employee_registration, org: org, individual: individual)
      payslip = insert(:payslip, org: org, registration: registration)

      items = [
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: Money.new(1_000_00),
          is_payment_advance: false
        ),
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :debit,
          amount: Money.new(400_00),
          is_payment_advance: true
        )
      ]

      # Update payslip amount
      Repo.update!(change(payslip, amount: 600_00))

      due_dates = %{payment_advance_date: "wrong", salary_date: "wrong"}

      assert CreateStandardPayables.call(registration, payslip, items, due_dates) ==
               {:error, "invalid payments due dates"}

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Adiantamento de Salário",
               amount: 400_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)

      refute Repo.get_by(Payable,
               org_id: org.id,
               target: :payslip,
               description: "Salário",
               amount: 600_00
             )

      refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)
    end
  end
end
