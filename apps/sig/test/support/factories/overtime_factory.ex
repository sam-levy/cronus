defmodule Sig.Factories.OvertimeFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Overtimes.Overtime

      def factory(:employee_overtime, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        date = random_past_date() |> Date.beginning_of_month()

        registration =
          Keyword.get(attrs, :registration) ||
            insert(:employee_registration, org: org, admission_date: date)

        %Overtime{
          org: org,
          date: date,
          hours_amount: "00:00",
          registration: registration
        }
      end
    end
  end
end
