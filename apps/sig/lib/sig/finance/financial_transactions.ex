defmodule Sig.Finance.FinancialTransactions do
  use Sig.Query, schema: __MODULE__.FinancialTransaction, as: :financial_transaction

  alias Sig.Finance.FinancialTransactions.Broadcaster
  alias Sig.Finance.FinancialTransactions.Creator
  alias Sig.Finance.FinancialTransactions.Deleter
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables
  alias Sig.Organizations.Org
  alias Sig.Repo

  defdelegate pay_payables_change(params \\ %{}), to: Creator
  defdelegate pay_payables(org, attrs \\ %{}), to: Creator
  defdelegate delete(financial_transaction), to: Deleter, as: :call

  defdelegate subscribe_to_financial_transactions(org), to: Broadcaster
  defdelegate unsubscribe_from_financial_transactions(org), to: Broadcaster
  defdelegate broadcast_new_financial_transaction(ft), to: Broadcaster
  defdelegate broadcast_updated_financial_transaction(ft), to: Broadcaster
  defdelegate broadcast_deleted_financial_transaction(ft), to: Broadcaster

  def default_preloads, do: [:bank_account, :created_by]

  def update_change(%FinancialTransaction{} = ft, %{} = attrs \\ %{}) do
    FinancialTransaction.update_changeset(ft, attrs)
  end

  def refetch(%FinancialTransaction{} = ft, opts \\ []) do
    init_query()
    |> where(org_id: ^ft.org_id)
    |> where(id: ^ft.id)
    |> shallow_preload(opts)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      ft -> {:ok, ft}
    end
  end

  def list_by(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(opts)
    |> filter_by(opts)
    |> handle_order_by(opts, [:clearing_date, :description])
    |> Repo.all()
  end

  def clear(%FinancialTransaction{clearing_date: nil} = ft, %{} = attrs) do
    ft
    |> FinancialTransaction.update_changeset(%{clearing_date: attrs.clearing_date})
    |> Repo.update()
    |> case do
      {:ok, ft} ->
        Task.start(fn -> Payables.broadcast_payables_for(ft) end)

        {:ok, ft}

      {:error, _} = error ->
        error
    end
  end

  def clear(%FinancialTransaction{}, %{}), do: {:error, "already cleared"}

  # TODO: Make it private once Summary is removed
  def query_by(%Org{} = org) do
    init_query() |> where(org_id: ^org.id)
  end

  @impl Sig.Query
  def filter_by(queryable, :clearing_date_period, dates) do
    case dates do
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

      _ ->
        queryable
    end
  end
end
