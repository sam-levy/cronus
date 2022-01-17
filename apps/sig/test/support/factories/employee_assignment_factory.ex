defmodule Sig.Factories.CompanyAssignmentFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment

      def factory(:employee_company_assignment, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        start_date = Keyword.get(attrs, :start_date) || random_past_date() |> Date.beginning_of_month()

        registration =
          Keyword.get(attrs, :registration) ||
            insert(:employee_registration, org: org, admission_date: start_date)

        company = Keyword.get(attrs, :company) || registration.registered_at

        %CompanyAssignment{
          org: org,
          registration: registration,
          company: company,
          start_date: start_date
        }
      end
    end
  end
end
