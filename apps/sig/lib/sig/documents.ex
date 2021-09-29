defmodule Sig.Documents do
  def format_cpf(cpf) do
    cpf |> raw_digits() |> BrazilianDocuments.format_cpf()
  end

  def format_cnpj(cnpj) do
    cnpj |> raw_digits() |> BrazilianDocuments.format_cnpj()
  end

  def format_document(document) do
    case format_cpf(document) do
      {:ok, cpf} ->
        {:cpf, cpf}

      :error ->
        case format_cnpj(document) do
          {:ok, cnpj} -> {:cnpj, cnpj}
          :error -> :error
        end
    end
  end

  def raw_digits(document) do
    document
    |> String.trim()
    |> String.replace(~r/\D/, "")
  end
end
