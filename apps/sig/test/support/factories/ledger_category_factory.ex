defmodule Sig.Factories.LedgerCategoryFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Accounting.LedgerCategories.LedgerCategory

      def factory(:ledger_category, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %LedgerCategory{
          org: org,
          code: random_string_number(5),
          description: sequence(&"#{Faker.Commerce.department()}#{&1}"),
          entry_type: random_enum_value(:entry_type),
          chart_of_account:
            Keyword.get(attrs, :chart_of_account) || insert(:chart_of_account, org: org)
        }
      end
    end
  end
end
