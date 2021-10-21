defmodule Sig.Factories.PayslipFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.Payslip

      def factory(:payslip, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        type = Keyword.get(attrs, :type) || random_enum_value(:payslip_group_type)

        start_date =
          Keyword.get(attrs, :start_date) || Date.utc_today() |> Date.beginning_of_month()

        group =
          Keyword.get(attrs, :group) ||
            insert(:payslip_group, org: org, type: type, date: Date.beginning_of_month(start_date))

        registration =
          Keyword.get(attrs, :registration) || insert(:employee_registration, org: org)

        %Payslip{
          org: org,
          type: type,
          amount: Enum.random(1_000_00..2_000_00),
          start_date: start_date,
          end_date: Date.end_of_month(start_date),
          is_closed: false,
          group: group,
          registration: registration
        }
      end
    end
  end
end
