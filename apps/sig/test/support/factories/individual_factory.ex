defmodule Sig.Factories.IndividualFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Entities.Individuals.Individual
      alias Sig.Entities.Individuals.Individual.Gender

      def factory(:individual, attrs) do
        organization = Keyword.get(attrs, :organization, insert(:organization))
        entity = Keyword.get(attrs, :entity, insert(:entity, organization: organization))

        %Individual{
          entity: entity,
          organization: organization,
          name: sequence(&"individual_name#{&1}"),
          cpf: BrazilianDocuments.generate_cpf(),
          gender: random_enum_value(Gender)
        }
      end
    end
  end
end
