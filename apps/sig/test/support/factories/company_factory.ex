defmodule Sig.Factories.CompanyFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Companies.Company

      def factory(:company) do
        %Company{
          entity: build(:entity),
          trade_name: Faker.Company.name(),
          registration_name: Faker.Company.name(),
          cnpj: BrazilianDocuments.generate_cnpj(),
          organization: build(:organization)
        }
      end
    end
  end
end
