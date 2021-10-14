defmodule Sig.Factories.EmployeeRegistraionRecurringPayslipItemFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem

      def factory({:employee_registration_recurring_payslip_item, :payslip_item}, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))
        category = Keyword.get(attrs, :category, insert(:payslip_category, org: org))

        %RecurringPayslipItem{
          org: org,
          registration: registration,
          type: :payslip_item,
          item_amount: Enum.random(100_00..5_000_00),
          payslip_category: category
        }
      end

      def factory({:employee_registration_recurring_payslip_item, :payslip_item_model}, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        payslip_recurring_item_model =
          Keyword.get(
            attrs,
            :payslip_recurring_item_model,
            insert({:payslip_recurring_item_model, :fixed_amount}, org: org)
          )

        %RecurringPayslipItem{
          org: org,
          registration: registration,
          type: :payslip_item_model,
          payslip_recurring_item_model: payslip_recurring_item_model
        }
      end

      def factory({:employee_registration_recurring_payslip_item, :outside_item}, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %RecurringPayslipItem{
          org: org,
          registration: registration,
          type: :outside_item,
          item_amount: Enum.random(100_00..5_000_00),
          outside_item_description: Faker.Lorem.sentence(),
          outside_item_entry_type: random_enum_value(:entry_type)
        }
      end
    end
  end
end
