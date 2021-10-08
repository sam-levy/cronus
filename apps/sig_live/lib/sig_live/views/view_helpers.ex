defmodule SigLive.ViewHelpers do
  alias BrazilianDocuments.Types.CPF

  alias Sig.Documents
  alias Sig.Entities.Companies.Company
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

  def bank_for_select(routing_number) when is_binary(routing_number) do
    %{bank_name_with_number(routing_number) => routing_number}
  end

  def bank_accounts_for_select(accounts) when is_list(accounts) do
    Map.new(accounts, fn account ->
      option =
        "#{bank_name_with_number(account.routing_number)} - Ag: #{account.branch_number} - Conta: #{account.number}"

      {option, account.id}
    end)
  end

  def enum_for_select(enum) do
    enum.__valid_values__()
    |> Enum.filter(&is_binary/1)
    |> Map.new(&{String.replace(&1, "_", " "), &1})
  end

  def list_for_select(list) when is_list(list) do
    Map.new(list, fn el ->
      el = to_string(el)

      {String.replace(el, "_", " "), el}
    end)
  end

  def format_cpf(%CPF{number: cpf}), do: format_cpf(cpf)

  def format_cpf(cpf) when is_binary(cpf) do
    case BrazilianDocuments.format_cpf(cpf) do
      {:ok, formatted_cpf} -> formatted_cpf
      _ -> ""
    end
  end

  def format_document(nil), do: ""

  def format_document(document) when is_binary(document) do
    case Documents.format_document(document) do
      {:cpf, cpf} -> cpf
      {:cnpj, cnpj} -> cnpj
      :error -> document
    end
  end

  def format_date(date, format \\ "%d/%m/%Y")
  def format_date(nil, _format), do: ""
  def format_date(date, format), do: Calendar.strftime(date, format)

  @spec companies_for_select([Company.t()]) :: %{String.t() => String.t()}
  def companies_for_select(companies) when is_list(companies) do
    Map.new(companies, &{&1.registration_name, &1.entity_id})
  end

  @spec id_by_name_for_select([map()]) :: %{String.t() => String.t()}
  def id_by_name_for_select(resources) when is_list(resources) do
    Map.new(resources, &{&1.name, &1.id})
  end

  def format_amount(%Money{} = amount), do: Money.to_string(amount)
  def format_amount(nil), do: ""
end
