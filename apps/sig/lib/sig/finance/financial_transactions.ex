defmodule Sig.Finance.FinancialTransactions do
  alias Sig.Finance.FinancialTransactions.Creator

  defdelegate pay_payables_change(params \\ %{}), to: Creator
  defdelegate pay_payables(org, attrs \\ %{}), to: Creator
end
