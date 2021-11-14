defmodule Sig.Factories.PayslipCategoryFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.Categories.Category

      def factory(:payslip_category, attrs) do
        %Category{
          org: insert(:org),
          code: random_string_number(),
          entry_type: :credit,
          description: Faker.Lorem.sentence(),
          is_payment_advance: false
        }
      end
    end
  end
end
