defmodule Sig.Factories.SalaryFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Salaries.Salary

      def factory(:employee_salary, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %Salary{
          org: org,
          registration: registration,
          start_date: Faker.Date.backward(100),
          amount: Enum.random(1_200_00..4_000_00)
        }
      end
    end
  end
end
