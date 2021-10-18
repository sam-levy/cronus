defmodule Sig.Factories.EmployeeBenefitModelFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.BenefitModels.BenefitModel
      alias Sig.HR.BenefitModels.BenefitType

      def factory(:employee_benefit_model, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        amount = Keyword.get(attrs, :amount, Enum.random(100_00..500_00))
        amount_date = Keyword.get(attrs, :amount_date, Faker.Date.backward(100))

        historical_amounts =
          Keyword.get(
            attrs,
            :historical_amounts,
            build(:historical_amount, amount: amount, amount_date: amount_date)
          )

        %BenefitModel{
          org: org,
          description: Faker.Lorem.sentence(),
          type: random_enum_value(:employee_benefit_type),
          amount: amount,
          amount_date: amount_date,
          historical_amounts: [historical_amounts]
        }
      end

      def random_enum_value(:employee_benefit_type) do
        random_enum_value(BenefitType)
      end
    end
  end
end
