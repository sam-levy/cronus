defmodule Sig.Factories.PayslipCategoryFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.Categories.Category

      def factory(:payslip_category, attrs) do
        %Category{
          org: insert(:org),
          code: random_string_number(),
          entry_type: random_enum_value(:entry_type),
          description: Faker.Lorem.sentence()
        }
      end
    end
  end
end
