defmodule Sig.Factories.IndividualFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Entities.Individual
      alias Sig.Organizations.Entities.Individual.Gender

      def factory(:individual) do
        %Individual{
          entity: build(:entity),
          name: sequence(&"individual_name#{&1}"),
          cpf: BrazilianDocuments.generate_cpf(),
          gender: random_enum_value(Gender),
          organization: build(:organization)
        }
      end
    end
  end
end
