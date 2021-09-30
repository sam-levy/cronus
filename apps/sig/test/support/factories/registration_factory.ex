defmodule Sig.Factories.RegistrationFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Registration
      alias Sig.HR.Registrations.Registration.ResignationType

      def factory(:employee_registration, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        individual = Keyword.get(attrs, :individual, insert(:individual, org: org))
        registered_at = Keyword.get(attrs, :registered_at, insert(:company, org: org))
        work_at = Keyword.get(attrs, :registered_at, registered_at)

        %Registration{
          org: org,
          admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
          resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
          resignation_type: random_enum_value(:registration_type),
          sector: build(:sector, org: org),
          position: build(:position, org: org),
          individual: individual,
          registered_at: registered_at,
          work_at: work_at
        }
      end

      def random_enum_value(:registration_type) do
        random_enum_value(ResignationType)
      end
    end
  end
end
