defmodule Sig.Finance.FinancialTransactions.Broadcaster do
  import Sig.Broadcaster

  alias Sig.Finance.FinancialTransactions
  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Organizations.Org

  def subscribe_to_financial_transactions(%Org{} = org) do
    subscribe(topics_for(org))
  end

  def unsubscribe_from_financial_transactions(%Org{} = org) do
    unsubscribe(topics_for(org))
  end

  def broadcast_new_financial_transaction(%FinancialTransaction{} = ft) do
    {:ok, ft} = FinancialTransactions.refetch(ft, preload: FinancialTransactions.default_preloads())

    broadcast(topics_for(ft), {:new_financial_transaction, ft})
  end

  def broadcast_updated_financial_transaction(%FinancialTransaction{} = ft) do
    {:ok, ft} = FinancialTransactions.refetch(ft, preload: FinancialTransactions.default_preloads())

    broadcast(topics_for(ft), {:updated_financial_transaction, ft})
  end

  def broadcast_deleted_financial_transaction(%FinancialTransaction{} = ft) do
    broadcast(topics_for(ft), {:deleted_financial_transaction, ft})
  end

  defp topics_for(%FinancialTransaction{} = ft) do
    org_fianancial_transactions_topic(ft.org_id)
  end

  defp topics_for(%Org{} = org) do
    org_fianancial_transactions_topic(org.id)
  end

  defp org_fianancial_transactions_topic(org_id) do
    "org_id:" <> org_id <> ":financial_transactions"
  end
end
