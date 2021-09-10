defmodule Sig.Factories.OrganizationFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Organization

      def factory(:organization) do
        %Organization{
          name: Faker.Company.name()
        }
      end
    end
  end
end
