defmodule Sig.Factories.EntityFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Entity
      alias Sig.Entities.Entity.EntityType

      def factory(:entity) do
        %Entity{
          org: build(:org),
          type: random_enum_value(EntityType)
        }
      end
    end
  end
end
