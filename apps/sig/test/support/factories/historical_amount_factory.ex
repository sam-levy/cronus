defmodule Sig.Factories.HistoricalAmountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.HistoricalAmount

      def factory(:historical_amount, attrs) do
        %HistoricalAmount{
          amount: Money.new(Enum.random(100_00..1_000_00)),
          date: Faker.Date.backward(365)
        }
      end
    end
  end
end
