defmodule Sig.HR.Registrations.RecurringPayslipItems.CreateFromPayslipTemplateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.RecurringPayslipItems.CreateFromPayslipTemplate
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem

  describe "call/2" do
    test "creates recurring payslip items from payslip template items" do
      %{id: org_id} = org = insert(:org)
      %{id: registration_id} = registration = insert(:employee_registration, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "Salário")

      transport_category =
        insert(:payslip_category,
          org: org,
          code: "109",
          entry_type: :debit,
          description: "Desc. Vale Transporte"
        )

      overtime_category =
        insert(:payslip_category,
          org: org,
          code: "82",
          entry_type: :credit,
          description: "Hora Extra 100%"
        )

      cashier_category =
        insert(:payslip_category,
          org: org,
          code: "1000",
          entry_type: :credit,
          description: "Quebra de Caixa"
        )

      salary_model =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: salary_category)

      transport_model =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          category: transport_category
        )

      payslip_template = insert(:payslip_template, org: org)

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: salary_model
      )

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: transport_model
      )

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: overtime_category
      )

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: cashier_category
      )

      assert {:ok,
              [
                %RecurringPayslipItem{org_id: ^org_id, registration_id: ^registration_id},
                %RecurringPayslipItem{org_id: ^org_id, registration_id: ^registration_id},
                %RecurringPayslipItem{org_id: ^org_id, registration_id: ^registration_id},
                %RecurringPayslipItem{org_id: ^org_id, registration_id: ^registration_id}
              ]} = CreateFromPayslipTemplate.call(registration, payslip_template.id)

      assert Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               payslip_recurring_item_model_id: salary_model.id,
               type: :payslip_item_model
             )

      assert Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               payslip_recurring_item_model_id: transport_model.id,
               type: :payslip_item_model
             )

      assert Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               payslip_category_id: overtime_category.id,
               type: :payslip_item
             )

      assert Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               payslip_category_id: cashier_category.id,
               type: :payslip_item
             )
    end

    test "existing recurring payslip items" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "Salário")

      transport_category =
        insert(:payslip_category,
          org: org,
          code: "109",
          entry_type: :debit,
          description: "Desc. Vale Transporte"
        )

      salary_model =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: salary_category)

      transport_model =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          category: transport_category
        )

      template = insert(:payslip_template, org: org)

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: template,
        payslip_recurring_item_model: salary_model
      )

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: template,
        payslip_recurring_item_model: transport_model
      )

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        registration: registration
      )

      assert CreateFromPayslipTemplate.call(registration, template.id) ==
               {:error, "o holerite modelo deve estar vazio"}
    end

    test "template has no items" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      template = insert(:payslip_template, org: org)

      assert CreateFromPayslipTemplate.call(registration, template.id) ==
               {:error, "não há items no modelo de holerite"}
    end

    test "invalid template id" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert CreateFromPayslipTemplate.call(registration, UUID.generate()) ==
               {:error, "não há items no modelo de holerite"}
    end

    test "template belongs to a different org" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      template = insert(:payslip_template)

      assert CreateFromPayslipTemplate.call(registration, template.id) ==
               {:error, "não há items no modelo de holerite"}
    end
  end
end
