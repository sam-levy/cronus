defmodule Sig.HR.Registrations.RecurringPayslipItems.ListByRegistrationTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem

  describe "call/1" do
    test "lists recurring payslip items ordered by code" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      insert(:employee_salary, org: org, registration: registration, amount: 2000_00)

      # outside_item

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        item_amount: 200_00,
        outside_item_description: "OUTSIDE ITEM DESCRIPTION",
        outside_item_entry_type: :credit
      )

      # payslip_item

      payslip_item_category =
        insert(:payslip_category,
          org: org,
          code: "123",
          entry_type: :credit,
          description: "PAYSLIP ITEM DESCRIPTION"
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        payslip_category: payslip_item_category,
        item_amount: 100_00
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
          amount: 43_05,
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

      # payslip_item_model employee_benefit

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :employee_health_insurance,
        amount: 300_00
      )

      employee_health_insurance_discount_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      benefit_payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Desconto Seguro Saúde 50%",
          percentage: 50,
          percentage_target: :employee_benefit,
          employee_benefit_type_percentage_target: :employee_health_insurance,
          category: employee_health_insurance_discount_category
        )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration,
        payslip_recurring_item_model: benefit_payslip_recurring_item_model
      )

      assert [
               %RecurringPayslipItem{code: "12"},
               %RecurringPayslipItem{code: "115"},
               %RecurringPayslipItem{code: "123"},
               %RecurringPayslipItem{code: "1038"},
               %RecurringPayslipItem{code: nil}
             ] = ListByRegistration.call(registration)
    end

    test "outside_item virtual fields" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :outside_item},
          org: org,
          registration: registration,
          item_amount: 200_00,
          outside_item_description: "OUTSIDE ITEM DESCRIPTION",
          outside_item_entry_type: :credit
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: nil,
                 description: "OUTSIDE ITEM DESCRIPTION",
                 entry_type: :credit,
                 amount: %Money{amount: 200_00}
               }
             ] = ListByRegistration.call(registration)
    end

    test "payslip_item virtual fields" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      category =
        insert(:payslip_category,
          org: org,
          code: "123",
          entry_type: :credit,
          description: "PAYSLIP ITEM DESCRIPTION"
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          payslip_category: category,
          item_amount: 100_00
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "123",
                 description: "PAYSLIP ITEM DESCRIPTION",
                 entry_type: :credit,
                 amount: %Money{amount: 100_00}
               }
             ] = ListByRegistration.call(registration)
    end

    test "payslip_item_model fixed amount virtual fields" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "QUEBRA DE CAIXA"
        )

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          description: "Quebra de Caixa - Mogi das Cruzes",
          category: category,
          amount: 60_70
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          registration: registration,
          payslip_recurring_item_model: payslip_recurring_item_model
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "1000",
                 description: "QUEBRA DE CAIXA",
                 entry_type: :credit,
                 amount: %Money{amount: 60_70}
               }
             ] = ListByRegistration.call(registration)
    end

    test "payslip_item_model virtual fields from employee_salary" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      insert(:employee_salary, org: org, registration: registration, amount: 1_000_00)

      category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Vale de Funcionários 40%",
          percentage: 40,
          percentage_target: :employee_salary,
          category: category
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          registration: registration,
          payslip_recurring_item_model: payslip_recurring_item_model
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "12",
                 description: "ADIANTAMENTO ANTERIOR",
                 entry_type: :debit,
                 amount: %Money{amount: 400_00}
               }
             ] = ListByRegistration.call(registration)
    end

    test "payslip_item_model virtual fields from employee_salary considers the salary in effect" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2020-01-01],
        amount: 1_000_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-01],
        amount: 1_200_00
      )

      insert(:employee_salary,
        org: org,
        registration: registration,
        start_date: ~D[2021-01-01],
        amount: 1_500_00
      )

      category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO"
        )

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Salário 100%",
          percentage: 100,
          percentage_target: :employee_salary,
          category: category
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          registration: registration,
          payslip_recurring_item_model: payslip_recurring_item_model
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "1",
                 description: "SALÁRIO",
                 entry_type: :credit,
                 amount: %Money{amount: 0}
               }
             ] = ListByRegistration.call(registration, ~D[2019-12-31])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "1",
                 description: "SALÁRIO",
                 entry_type: :credit,
                 amount: %Money{amount: 1_000_00}
               }
             ] = ListByRegistration.call(registration, ~D[2020-02-01])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "1",
                 description: "SALÁRIO",
                 entry_type: :credit,
                 amount: %Money{amount: 1_200_00}
               }
             ] = ListByRegistration.call(registration, ~D[2020-07-01])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "1",
                 description: "SALÁRIO",
                 entry_type: :credit,
                 amount: %Money{amount: 1_500_00}
               }
             ] = ListByRegistration.call(registration, ~D[2021-02-01])
    end

    test "payslip_item_model virtual fields from employee_benefit" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :employee_health_insurance,
        amount: 300_00
      )

      category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Desconto Seguro Saúde 50%",
          percentage: 50,
          percentage_target: :employee_benefit,
          employee_benefit_type_percentage_target: :employee_health_insurance,
          category: category
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          registration: registration,
          payslip_recurring_item_model: payslip_recurring_item_model
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "115",
                 description: "ASSISTÊNCIA MÉDICA",
                 entry_type: :debit,
                 amount: %Money{amount: 150_00}
               }
             ] = ListByRegistration.call(registration)
    end

    test "payslip_item_model virtual fields from employee_benefit considers the benefit in effect" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :employee_health_insurance,
        amount: 300_00,
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :employee_health_insurance,
        amount: 350_00,
        start_date: ~D[2021-01-01]
      )

      category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :percentage},
          org: org,
          description: "Desconto Seguro Saúde 50%",
          percentage: 50,
          percentage_target: :employee_benefit,
          employee_benefit_type_percentage_target: :employee_health_insurance,
          category: category
        )

      %{id: id} =
        insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          registration: registration,
          payslip_recurring_item_model: payslip_recurring_item_model
        )

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "115",
                 description: "ASSISTÊNCIA MÉDICA",
                 entry_type: :debit,
                 amount: %Money{amount: 0}
               }
             ] = ListByRegistration.call(registration, ~D[2019-12-31])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "115",
                 description: "ASSISTÊNCIA MÉDICA",
                 entry_type: :debit,
                 amount: %Money{amount: 150_00}
               }
             ] = ListByRegistration.call(registration, ~D[2020-02-01])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "115",
                 description: "ASSISTÊNCIA MÉDICA",
                 entry_type: :debit,
                 amount: %Money{amount: 0}
               }
             ] = ListByRegistration.call(registration, ~D[2020-07-01])

      assert [
               %RecurringPayslipItem{
                 id: ^id,
                 code: "115",
                 description: "ASSISTÊNCIA MÉDICA",
                 entry_type: :debit,
                 amount: %Money{amount: 175_00}
               }
             ] = ListByRegistration.call(registration, ~D[2021-01-01])
    end

    test "when registration has no recurring payslip items" do
      registration = insert(:employee_registration)

      assert ListByRegistration.call(registration) == []
    end

    # TODO: Test aggregation of models from the same type
  end
end
