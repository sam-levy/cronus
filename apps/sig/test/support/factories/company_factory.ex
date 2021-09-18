defmodule Sig.Factories.CompanyFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Companies.Company

      def factory(:company, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org))

        %Company{
          entity: entity,
          org: org,
          trade_name: Faker.Company.name(),
          registration_name: Faker.Company.name(),
          cnpj: BrazilianDocuments.generate_cnpj()
        }
      end
    end
  end
end
