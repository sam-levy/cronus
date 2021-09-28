defmodule SigLive.ViewHelpers do
  alias BrazilianDocuments.Types.CPF

  alias Sig.Finance
  alias Sig.Finance.Banks.Bank

  def bank_name(routing_number) when is_binary(routing_number) do
    case Finance.fetch_bank(routing_number) do
      {:ok, bank} -> bank.name
      {:error, :not_found} -> ""
    end
  end

  def bank_name_with_number(routing_number) when is_binary(routing_number) do
    case Finance.fetch_bank(routing_number) do
      {:ok, bank} -> bank_name_with_number(bank)
      {:error, :not_found} -> ""
    end
  end

  def bank_name_with_number(%Bank{} = bank) do
    bank.routing_number <> " - " <> bank.name
  end

  @spec banks_for_select([Bank.t()]) :: %{String.t() => String.t()}
  def banks_for_select(banks) when is_list(banks) do
    Map.new(banks, &{bank_name_with_number(&1), &1.routing_number})
  end

  def enum_for_select(enum) do
    enum.__valid_values__()
    |> Enum.filter(&is_binary/1)
    |> Map.new(&{String.replace(&1, "_", " "), &1})
  end

  def format_cpf(%CPF{number: cpf}), do: format_cpf(cpf)

  def format_cpf(cpf) when is_binary(cpf) do
    case BrazilianDocuments.format_cpf(cpf) do
      {:ok, formatted_cpf} -> formatted_cpf
      _ -> ""
    end
  end
end
