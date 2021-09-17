defmodule Sig.Factories.CompanyFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Companies.Company

      def factory(:company, attrs) do
        organization = Keyword.get(attrs, :organization, insert(:organization))
        entity = Keyword.get(attrs, :entity, insert(:entity, organization: organization))

        %Company{
          entity: entity,
          organization: organization,
          trade_name: Faker.Company.name(),
          registration_name: Faker.Company.name(),
          cnpj: BrazilianDocuments.generate_cnpj()
        }
      end
    end
  end
end
