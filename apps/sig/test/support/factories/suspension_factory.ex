defmodule Sig.Factories.SuspensionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Suspensions.Suspension

      def factory(:employee_suspension, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))
        start_date = Keyword.get(attrs, :start_date, Date.utc_today())

        %Suspension{
          org: org,
          registration: registration,
          description: Faker.Lorem.paragraph(1),
          start_date: start_date,
          end_date: Date.add(start_date, 3)
        }
      end
    end
  end
end
