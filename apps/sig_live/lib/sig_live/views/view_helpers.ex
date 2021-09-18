defmodule SigLive.ViewHelpers do
	alias BrazilianDocuments.Types.CPF

	def format_cpf(%CPF{number: cpf}), do: format_cpf(cpf)

	def format_cpf(cpf) when is_binary(cpf) do
		case BrazilianDocuments.format_cpf(cpf) do
			{:ok, formatted_cpf} -> formatted_cpf
			_ -> ""
		end
	end
end
