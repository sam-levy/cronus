defmodule Sig.Factories.SalaryFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Salaries.Salary

      def factory(:employee_salary, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        start_date =
          Keyword.get(attrs, :start_date) || random_past_date() |> Date.beginning_of_month()

        registration =
          Keyword.get(attrs, :registration) ||
            insert(:employee_registration, org: org, admission_date: start_date)

        %Salary{
          org: org,
          registration: registration,
          start_date: start_date,
          amount: Enum.random(1_200_00..4_000_00)
        }
      end
    end
  end
end
