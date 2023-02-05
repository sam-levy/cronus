defmodule Sig.Factories.ChartOfAccountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Accounting.ChartOfAccounts.ChartOfAccount

      def factory(:chart_of_account) do
        %ChartOfAccount{
          org: build(:org),
          name: sequence(&"#{Faker.Company.bullshit_prefix()}_#{&1}")
        }
      end
    end
  end
end
