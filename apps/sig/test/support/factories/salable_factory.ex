defmodule Sig.Factories.SalableFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Accounting.Salables.Salable
      alias Sig.Accounting.Salables.Salable.SalableType

      def factory(:salable, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %Salable{
          org: org,
          type: random_enum_value(:salable_type),
          code: random_string_number(5),
          description: sequence(&"#{Faker.Commerce.product_name()}#{&1}"),
          unit: "Kg",
          entity: Keyword.get(attrs, :entity) || insert(:entity, org: org)
        }
      end

      def random_enum_value(:salable_type) do
        random_enum_value(SalableType)
      end
    end
  end
end
