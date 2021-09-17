defmodule Sig.Factories.EntityFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Entity

      def factory(:entity) do
        %Entity{
          organization: build(:organization)
        }
      end
    end
  end
end
