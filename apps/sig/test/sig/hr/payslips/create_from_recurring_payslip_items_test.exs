defmodule Sig.HR.Payslips.CreateFromRecurringPayslipItemsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.CreateFromRecurringPayslipItems
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

      assert {:ok, %Payslip{id: id}} = CreateFromRecurringPayslipItems.call(registration, attrs)

      assert payslip =
               Repo.get_by(Payslip,
                 #  amount: 732_00,
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
  end
end
