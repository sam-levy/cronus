defmodule Sig.Factories.PayslipRecurringItemModelFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel

      def factory(:payslip_recurring_item_model, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        category = Keyword.get(attrs, :category, insert(:payslip_category, org: org))

        %RecurringItemModel{
          org: org,
          description: Faker.Lorem.sentence(),
          is_fixed_amount: true,
          amount: 200_00,
          category: category
        }
      end
    end
  end
end
