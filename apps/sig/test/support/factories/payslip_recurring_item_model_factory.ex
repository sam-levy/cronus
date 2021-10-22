defmodule Sig.Factories.PayslipRecurringItemModelFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel

      def factory({:payslip_recurring_item_model, :fixed_amount}, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        category = Keyword.get(attrs, :category) || insert(:payslip_category, org: org)

        %RecurringItemModel{
          org: org,
          description: Faker.Lorem.sentence(),
          category: category,
          is_fixed_amount: true,
          amount: Enum.random(100_00..1_000_00)
        }
      end

      def factory({:payslip_recurring_item_model, :percentage}, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        category = Keyword.get(attrs, :category) || insert(:payslip_category, org: org)

        %RecurringItemModel{
          org: org,
          description: Faker.Lorem.sentence(),
          category: category,
          is_fixed_amount: false,
          percentage: Enum.random(0..100),
          percentage_target: :employee_salary
        }
      end
    end
  end
end
