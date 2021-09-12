defmodule SigLive.ViewHelpers do
	def format_cpf(cpf) do
		case BrazilianDocuments.format_cpf(cpf) do
			{:ok, formatted_cpf} -> formatted_cpf
			_ -> ""
		end
	end
end
