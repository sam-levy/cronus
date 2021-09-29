defmodule Sig.Finance.Banks do
  alias Sig.Finance.Banks.Bank

  banks_file = Application.app_dir(:sig, "priv/assets/brazilian-banks.json")
  @external_resource banks_file

  banks =
    banks_file
    |> File.read!()
    |> Jason.decode!()

  @all_banks Enum.map(banks, fn bank ->
               %Bank{
                 name: bank["LongName"],
                 routing_number: bank["COMPE"]
               }
             end)

  @banks_by_routing_number Map.new(@all_banks, &{&1.routing_number, &1})

  def list_banks, do: @all_banks

  def fetch_bank(routing_number) do
    case Map.get(@banks_by_routing_number, routing_number) do
      %Bank{} = bank -> {:ok, bank}
      nil -> {:error, :not_found}
    end
  end

  def valid_routing_number?(routing_number) do
    Map.has_key?(@banks_by_routing_number, routing_number)
  end
end
