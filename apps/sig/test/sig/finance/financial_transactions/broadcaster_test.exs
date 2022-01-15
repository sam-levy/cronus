defmodule Sig.Finance.FinancialTransactions.BroadcasterTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.FinancialTransactions.Broadcaster

  @endpoint SigLive.Endpoint

  describe "subscribe_to_financial_transactions/1" do
    test "subscribes to financial transactions topic" do
      org = insert(:org)

      topic = "org_id:" <> org.id <> ":financial_transactions"

      assert Broadcaster.subscribe_to_financial_transactions(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:new_financial_transaction, :transaction})

      assert_receive {:new_financial_transaction, :transaction}
    end
  end

  describe "unsubscribe_from_financial_transactions/1" do
    test "unsubscribes from financial transactions topic" do
      org = insert(:org)

      topic = "org_id:" <> org.id <> ":financial_transactions"

      @endpoint.subscribe(topic)

      assert Broadcaster.unsubscribe_from_financial_transactions(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:new_financial_transaction, :transaction})

      refute_receive {:updated_payables, :payables}
    end
  end

  describe "broadcast_new_financial_transaction/1" do
    test "broadcasts payables from a payslip" do
      %{id: ft_id} = ft = insert(:financial_transaction)

      topic = "org_id:" <> ft.org_id <> ":financial_transactions"

      @endpoint.subscribe(topic)

      assert Broadcaster.broadcast_new_financial_transaction(ft) == :ok

      assert_receive {:new_financial_transaction, %{id: ^ft_id}}

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_financial_transaction/1" do
    test "broadcasts payables from a payslip" do
      %{id: ft_id} = ft = insert(:financial_transaction)

      topic = "org_id:" <> ft.org_id <> ":financial_transactions"

      @endpoint.subscribe(topic)

      assert Broadcaster.broadcast_updated_financial_transaction(ft) == :ok

      assert_receive {:updated_financial_transaction, %{id: ^ft_id}}

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_financial_transaction/1" do
    test "broadcasts payables from a payslip" do
      %{id: ft_id} = ft = insert(:financial_transaction)

      topic = "org_id:" <> ft.org_id <> ":financial_transactions"

      @endpoint.subscribe(topic)

      assert Broadcaster.broadcast_deleted_financial_transaction(ft) == :ok

      assert_receive {:deleted_financial_transaction, %{id: ^ft_id}}

      @endpoint.unsubscribe(topic)
    end
  end
end
