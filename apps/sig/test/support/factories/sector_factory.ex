defmodule Sig.Factories.SectorFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Organizations.Sector

      def factory(:org_sector) do
        %Sector{
          org: build(:org),
          name: sequence(&"#{Faker.Company.bullshit_prefix()}_#{&1}")
        }
      end
    end
  end
end
