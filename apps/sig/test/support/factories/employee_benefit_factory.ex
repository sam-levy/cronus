defmodule Sig.Factories.EmployeeBenefitFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Benefits.Benefit

      def factory(:employee_benefit, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %Benefit{
          org: org,
          registration: registration,
          description: Faker.Lorem.sentence(),
          benefit_type: random_enum_value(:employee_benefit_type),
          benefit_amount: Enum.random(400_00..600_00),
          is_for_dependent: false,
          is_from_model: false,
          start_date: Faker.Date.backward(100)
        }
      end

      def factory(:employee_benefit_from_model, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        benefit_model =
          Keyword.get(attrs, :employee_benefit_model, insert(:employee_benefit_model, org: org))

        %Benefit{
          org: org,
          registration: registration,
          description: Faker.Lorem.sentence(),
          is_for_dependent: false,
          is_from_model: true,
          start_date: Faker.Date.backward(100),
          benefit_model: benefit_model
        }
      end
    end
  end
end
