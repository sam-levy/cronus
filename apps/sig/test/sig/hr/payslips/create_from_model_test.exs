defmodule Sig.HR.Payslips.CreateFromModelTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.CreateFromModel
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Payslip

  describe "call/1" do
    test "creates a payslip with payslip items from recurring payslip items" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-02-01])

      insert(:employee_salary,
        org: org,
        registration: registration,
        amount: 1_000_00,
        start_date: ~D[2021-02-01]
      )

      # outside_item

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 200_00,
        outside_item_description: "COMPLEMENTO SALÁRIO",
        outside_item_entry_type: :credit
      )

      # payslip_item

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        item_amount: 1_000_00,
        payslip_category: salary_category
      )

      # payslip_item_model fixed amount

      uniform_cleanning_category =
        insert(:payslip_category,
          org: org,
          code: "1038",
          entry_type: :credit,
          description: "LAVAR UNIFORME"
        )

      fixed_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          description: "Lavagem de uniformes - Mogi das Cruzes",
          amount: 50_00,
          category: uniform_cleanning_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: fixed_payslip_recurring_item_model
      )

      # payslip_item_model employee_salary

      salary_in_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      salary_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Vale de Funcionários 40%",
          percentage: 40,
          percentage_target: :employee_salary,
          category: salary_in_advance_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: salary_payslip_recurring_item_model
      )

      # payslip_item_model employee_benefit is_from_model false

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount_date: ~D[2021-02-01],
        benefit_amount: 200_00
      )

      health_insurance_discount_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      health_insurance_benefit_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Desconto Seguro Saúde 50%",
          percentage: 50,
          percentage_target: :employee_benefit,
          employee_benefit_type_percentage_target: :health_insurance,
          category: health_insurance_discount_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: health_insurance_benefit_payslip_recurring_item_model
      )

      # payslip_item_model employee_benefit is_from_model true

      historical_amounts = [
        build(:historical_amount, date: ~D[2021-01-01], amount: %Money{amount: 300_00}),
        build(:historical_amount, date: ~D[2020-06-01], amount: %Money{amount: 200_00})
      ]

      transportation_voucher_benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :transportation_voucher,
          amount_date: ~D[2021-01-01],
          amount: 300_00,
          historical_amounts: historical_amounts
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        start_date: ~D[2020-04-01],
        benefit_model: transportation_voucher_benefit_model
      )

      transportation_voucher_discount_category =
        insert(:payslip_category,
          org: org,
          code: "109",
          entry_type: :debit,
          description: "DESC. VALE TRANSPORTE"
        )

      transportation_voucher_benefit_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Desconto Vale Transporte 6%",
          percentage: 6,
          percentage_target: :employee_benefit,
          employee_benefit_type_percentage_target: :transportation_voucher,
          category: transportation_voucher_discount_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: transportation_voucher_benefit_payslip_recurring_item_model
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert {:ok, %Payslip{id: id}} = CreateFromModel.call(registration, attrs)

      assert payslip =
               Repo.get_by(Payslip,
                 amount: 732_00,
                 id: id,
                 org_id: org.id,
                 registration_id: registration.id,
                 type: attrs[:type],
                 start_date: attrs[:start_date],
                 end_date: attrs[:end_date]
               )

      assert [
               %Item{code: "1", amount: %Money{amount: 1_000_00}},
               %Item{code: "1038", amount: %Money{amount: 50_00}},
               %Item{code: "109", amount: %Money{amount: 18_00}},
               %Item{code: "115", amount: %Money{amount: 100_00}},
               %Item{code: "12", amount: %Money{amount: 400_00}},
               %Item{code: nil, amount: %Money{amount: 200_00}}
             ] = Items.list_by_payslip(payslip)
    end

    test "when there are duplicated recurring payslip items" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-02-01])

      insert(:employee_salary,
        org: org,
        registration: registration,
        amount: 1_000_00,
        start_date: ~D[2021-02-01]
      )

      # outside_item

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 200_00,
        outside_item_description: "COMPLEMENTO SALÁRIO",
        outside_item_entry_type: :credit
      )

      # payslip_item

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        item_amount: 1_000_00,
        payslip_category: salary_category
      )

      # duplicated payslip_item

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        item_amount: 2_000_00,
        payslip_category: salary_category
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert CreateFromModel.call(registration, attrs) ==
               {:error, "Existem itens duplicados no holerite modelo"}

      refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)
    end

    test "when recurring payslip items amount sum is negative" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-02-01])

      insert(:employee_salary,
        org: org,
        registration: registration,
        amount: 1_000_00,
        start_date: ~D[2021-02-01]
      )

      # outside_item

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 1_100_00,
        outside_item_entry_type: :debit
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert CreateFromModel.call(registration, attrs) ==
               {:error, "payslip amount can't be negative"}

      refute Repo.get_by(Payslip, org_id: org.id, registration_id: registration.id)
    end

    test "when there is no recurring payslip items" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org, admission_date: ~D[2021-02-01])

      attrs = %{
        type: :regular,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-28]
      }

      assert {:ok, %Payslip{id: id}} = CreateFromModel.call(registration, attrs)

      assert payslip =
               Repo.get_by(Payslip,
                 amount: 0,
                 id: id,
                 org_id: org.id,
                 registration_id: registration.id,
                 type: attrs[:type],
                 start_date: attrs[:start_date],
                 end_date: attrs[:end_date]
               )

      assert Items.list_by_payslip(payslip) == []
    end

    test "creates standard payables" do
      org = insert(:org)
      individual = insert(:individual, org: org)
      bank_account = insert(:bank_account, org: org, entity: individual.entity, is_primary: true)
      registration = insert(:employee_registration, org: org, individual: individual)

      insert(:employee_salary,
        org: org,
        registration: registration,
        amount: 1_000_00,
        start_date: ~D[2021-01-01]
      )

      # payslip_item

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        item_amount: 1_000_00,
        payslip_category: salary_category
      )

      # payslip_item_model employee_salary

      salary_in_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR",
          is_payment_advance: true
        )

      salary_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Vale de Funcionários 40%",
          percentage: 40,
          percentage_target: :employee_salary,
          category: salary_in_advance_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: salary_payslip_recurring_item_model
      )

      # outside_item

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 100_00,
        outside_item_description: "DESCONTO QUALQUER",
        outside_item_entry_type: :debit,
        outside_item_is_payment_advance: false
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-31]
      }

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}
      opts = [payables_attrs: %{type: :standard, due_dates: due_dates}]

      assert {:ok, %Payslip{id: id}} = CreateFromModel.call(registration, attrs, opts)

      assert payslip =
               Repo.get_by(Payslip,
                 amount: 500_00,
                 id: id,
                 org_id: org.id,
                 registration_id: registration.id,
                 type: attrs[:type],
                 start_date: attrs[:start_date],
                 end_date: attrs[:end_date]
               )

      assert [
               %Item{code: "1", amount: %Money{amount: 1_000_00}},
               %Item{code: "12", amount: %Money{amount: 400_00}},
               %Item{code: nil, amount: %Money{amount: 100_00}}
             ] = Items.list_by_payslip(payslip)

      assert payment_advance_payable =
               Repo.get_by(Payable,
                 org_id: org.id,
                 target: :payslip,
                 description: "Adiantamento de Salário",
                 amount: 400_00,
                 due_date: ~D[2021-01-20],
                 reference_date: Date.beginning_of_month(payslip.start_date),
                 method: :bank_transfer,
                 credit_bank_account_id: bank_account.id
               )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: payment_advance_payable.id,
               is_auto_adjustable_amount: false
             )

      assert salary_payable =
               Repo.get_by(Payable,
                 org_id: org.id,
                 target: :payslip,
                 description: "Salário",
                 amount: 500_00,
                 due_date: ~D[2021-02-05],
                 reference_date: Date.beginning_of_month(payslip.start_date),
                 method: :bank_transfer,
                 credit_bank_account_id: bank_account.id
               )

      assert Repo.get_by(PayslipPayable,
               org_id: org.id,
               payslip_id: payslip.id,
               payable_id: salary_payable.id,
               is_auto_adjustable_amount: true
             )
    end

    test "wrong payables attrs" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # payslip_item

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        item_amount: 1_000_00,
        payslip_category: salary_category
      )

      attrs = %{
        type: :regular,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-31]
      }

      due_dates = %{payment_advance_date: ~D[2021-01-20], salary_date: ~D[2021-02-05]}
      opts = [payables_attrs: %{type: :wrong, due_dates: due_dates}]

      assert CreateFromModel.call(registration, attrs, opts) == {:error, "invalid payables attrs"}
    end
  end
end
