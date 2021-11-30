defmodule Sig.Factories.LeavePeriodFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.LeavePeriods.LeavePeriod
      alias Sig.HR.Registrations.LeavePeriods.LeavePeriod.LeavePeriodType

      def factory(:employee_leave_period, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        registration =
          Keyword.get(attrs, :registration) || insert(:employee_registration, org: org)

        start_date = Keyword.get(attrs, :start_date) || Date.utc_today()

        %LeavePeriod{
          org: org,
          registration: registration,
          type: random_enum_value(:employee_leave_period_type),
          start_date: start_date,
          end_date: Date.add(start_date, 30)
        }
      end

      def random_enum_value(:employee_leave_period_type) do
        random_enum_value(LeavePeriodType)
      end
    end
  end
end
