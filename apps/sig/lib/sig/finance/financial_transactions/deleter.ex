defmodule Sig.Finance.FinancialTransactions.Deleter do
  import Ecto.Query
  import Sig.Enums.FinancialTransaction, only: [is_bank_type: 1]

  alias Ecto.Multi

  alias Sig.Finance.FinancialTransactions.BankTransactions.BankTransaction
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Repo

  def call(%FinancialTransaction{type: :cash} = ft) do
    %{org: org} = Repo.preload(ft, :org)

    Multi.new()
    |> Multi.update_all(:payable_ids, fn _ -> update_payables_query(ft) end, [])
    |> Multi.delete(:financial_transaction, ft)
    |> Repo.transaction()
    |> handle_delete_return(org)
  end

  def call(%FinancialTransaction{type: type} = ft) when is_bank_type(type) do
    %{org: org} = Repo.preload(ft, :org)

    Multi.new()
    |> Multi.update_all(:payable_ids, fn _ -> update_payables_query(ft) end, [])
    |> Multi.delete_all(
      :bank_transaction,
      BankTransaction
      |> where(org_id: ^ft.org_id)
      |> where(financial_transaction_id: ^ft.id)
    )
    |> Multi.delete(:financial_transaction, ft)
    |> Repo.transaction()
    |> handle_delete_return(org)
  end

  defp update_payables_query(financial_transaction) do
    Payable
    |> where(org_id: ^financial_transaction.org_id)
    |> where([p], p.financial_transaction_id == ^financial_transaction.id)
    |> update(set: [financial_transaction_id: nil])
    |> select([p], p.id)
  end

  defp handle_delete_return(
         {:ok, %{payable_ids: {_, payable_ids}, financial_transaction: financial_transaction}},
         org
       ) do
    Task.Supervisor.start_child(
      Sig.BroadcastSupervisor,
      fn ->
        Payables.broadcast_payables(org, payable_ids)
      end,
      restart: :transient
    )

    {:ok, financial_transaction}
  end

  defp handle_delete_return({:error, _operation, reason, _changes}, _org), do: {:error, reason}
end
