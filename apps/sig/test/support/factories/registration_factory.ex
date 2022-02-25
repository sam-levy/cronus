defmodule Sig.Factories.RegistrationFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Registration
      alias Sig.HR.Registrations.Registration.ResignationType

      def factory(:employee_registration, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        individual = Keyword.get(attrs, :individual) || insert(:individual, org: org)
        registered_at = Keyword.get(attrs, :registered_at) || insert(:company, org: org)

        %Registration{
          org: org,
          number: random_string_number(),
          e_social_number: random_string_number(),
          admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
          sector: build(:org_sector, org: org),
          individual: individual,
          registered_at: registered_at
        }
      end

      def random_enum_value(:resignation_type) do
        random_enum_value(ResignationType)
      end
    end
  end
end
