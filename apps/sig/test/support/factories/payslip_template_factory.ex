defmodule Sig.Factories.PayslipTemplateFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.PayslipTemplates.PayslipTemplate

      def factory(:payslip_template, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %PayslipTemplate{
          org: org,
          name: Faker.Commerce.department()
        }
      end
    end
  end
end
