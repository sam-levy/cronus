defmodule Sig.Factories.WarningFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Warnings.Warning

      def factory(:employee_warning, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %Warning{
          org: org,
          registration: registration,
          date: Faker.Date.backward(20),
          description: Faker.Lorem.paragraph(1)
        }
      end
    end
  end
end
