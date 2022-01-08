defmodule Sig.Enums.FinancialTransaction do
  import EctoEnum

  @bank_types [:check, :billet, :bank_transfer]
  @cash_type [:cash]

  @types @bank_types ++ @cash_type

  defenum(Type, :financial_transaction_type, @types)

  defguard is_bank_type(type) when type in @bank_types

  def bank_types, do: @bank_types
end
