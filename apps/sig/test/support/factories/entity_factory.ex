defmodule Sig.Factories.EntityFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Entity

      def factory(:entity) do
        %Entity{
          org: build(:org)
        }
      end
    end
  end
end
