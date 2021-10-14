defmodule Sig.Factories.EmployeeBenefitFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Benefits.Benefit
      alias Sig.HR.Registrations.Benefits.Benefit.BenefitType

      def factory(:employee_benefit, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %Benefit{
          org: org,
          registration: registration,
          description: Faker.Lorem.sentence(),
          type: random_enum_value(:employee_benefit_type),
          amount: Enum.random(400_00..600_00),
          is_for_dependent: Enum.random([true, false]),
          start_date: Faker.Date.backward(100)
        }
      end

      def random_enum_value(:employee_benefit_type) do
        random_enum_value(BenefitType)
      end
    end
  end
end
