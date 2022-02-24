defmodule Sig.Factories.RegistrationPositionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition

      def factory(:registration_position, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        start_date =
          Keyword.get(attrs, :start_date) || random_past_date() |> Date.beginning_of_month()

        registration =
          Keyword.get(attrs, :registration) ||
            insert(:employee_registration, org: org, admission_date: start_date)

        position = Keyword.get(attrs, :position) || insert(:org_position, org: org)

        %RegistrationPosition{
          org: org,
          start_date: start_date,
          registration: registration,
          position: position
        }
      end
    end
  end
end
