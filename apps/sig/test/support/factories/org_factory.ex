defmodule Sig.Factories.OrgFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Org

      def factory(:org) do
        %Org{
          name: Faker.Company.name()
        }
      end
    end
  end
end
