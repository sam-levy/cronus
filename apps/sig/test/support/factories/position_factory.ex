defmodule Sig.Factories.PositionFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Position
      alias Sig.Organizations.Org

      def factory(:org_position) do
        %Position{
          org: build(:org),
          name: sequence(&"#{Faker.Superhero.name()}_#{&1}")
        }
      end
    end
  end
end
