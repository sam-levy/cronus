defmodule Sig.Finance.FinancialTransactions do
  import Ecto.Query

  alias Sig.Finance.FinancialTransactions.Broadcaster
  alias Sig.Finance.FinancialTransactions.Creator
  alias Sig.Finance.FinancialTransactions.Deleter
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Organizations.Org
  alias Sig.Repo

  defdelegate pay_payables_change(params \\ %{}), to: Creator
  defdelegate pay_payables(org, attrs \\ %{}), to: Creator
  defdelegate delete(financial_transaction), to: Deleter

  defdelegate subscribe_to_financial_transactions(org), to: Broadcaster
  defdelegate unsubscribe_from_financial_transactions(org), to: Broadcaster
  defdelegate broadcast_new_financial_transaction(ft), to: Broadcaster
  defdelegate broadcast_updated_financial_transaction(ft), to: Broadcaster
  defdelegate broadcast_deleted_financial_transaction(ft), to: Broadcaster

  def list_by(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> filter_by_clearing_date(opts)
    |> order()
    |> Repo.all()
  end

  defp init_query, do: from(p in FinancialTransaction, as: :financial_transaction)

  defp query_by(%Org{} = org) do
    init_query() |> where(org_id: ^org.id)
  end

  defp filter_by_clearing_date(queryable, opts) do
    case Keyword.get(opts, :clearing_date, nil) do
      nil ->
        queryable

      [period_start: period_start, period_end: period_end] ->
        queryable
        |> where(
          [financial_transaction: ft],
          ft.clearing_date >= ^period_start and ft.clearing_date <= ^period_end
        )
        |> or_where(
          [financial_transaction: ft],
          is_nil(ft.clearing_date) and
            (ft.placement_date <= ^period_start or ft.placement_date <= ^period_end)
        )
    end
  end

  defp order(queryable) do
    order_by(queryable, [:clearing_date, :description])
  end
end
