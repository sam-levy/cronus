defmodule Sig.Factories.IndividualFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Individuals.Individual
      alias Sig.Entities.Individuals.Individual.Gender

      def factory(:individual, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org))

        %Individual{
          entity: entity,
          org: org,
          name: sequence(&"individual_name#{&1}"),
          cpf: BrazilianDocuments.generate_cpf(),
          gender: random_enum_value(:gender)
        }
      end

      def random_enum_value(:gender) do
        random_enum_value(Gender)
      end
    end
  end
end
