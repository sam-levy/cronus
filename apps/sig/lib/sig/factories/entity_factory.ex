defmodule Sig.Factories.EntityFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Entities.Entity

      def factory(:entity), do: %Entity{}
    end
  end
end
