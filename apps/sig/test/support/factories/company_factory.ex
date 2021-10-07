defmodule Sig.Factories.CompanyFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Companies.Company

      def factory(:company, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org, type: :company))

        %Company{
          org: org,
          entity: entity,
          is_virtual: false,
          trade_name: sequence(&"#{Faker.Company.name()}_#{&1}"),
          registration_name: sequence(&"#{Faker.Company.name()}_#{&1}"),
          cnpj: BrazilianDocuments.generate_cnpj()
        }
      end

      def factory(:virtual_company, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org, type: :company))

        %Company{
          org: org,
          entity: entity,
          is_virtual: true,
          trade_name: sequence(&"#{Faker.Company.name()}_#{&1}")
        }
      end
    end
  end
end
