defmodule Sig.Finance.Payables.BroadcasterTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Broadcaster

  @endpoint SigLive.Endpoint

  describe "subscribe_to_payables/1" do
    test "subscribes to payables for payslip topic" do
      payslip = insert(:payslip)

      payslip_payables_topic =
        "org_id:" <> payslip.org_id <> ":payslip_id:" <> payslip.id <> ":payables"

      org_payables_topic = "org_id:" <> payslip.org_id <> ":payables"

      assert Broadcaster.subscribe_to_payables(payslip) == :ok

      ####### payslip_payables_topic #######
      Phoenix.PubSub.broadcast(Sig.PubSub, payslip_payables_topic, {:updated_payables, :payables})
      assert_receive {:updated_payables, :payables}

      ####### org_payables_topic #######
      Phoenix.PubSub.broadcast(Sig.PubSub, org_payables_topic, {:updated_payables, :payables})
      assert_receive {:updated_payables, :payables}
    end

    test "subscribes to payables for org topic" do
      org = insert(:org)

      org_payables_topic = "org_id:" <> org.id <> ":payables"

      assert Broadcaster.subscribe_to_payables(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, org_payables_topic, {:updated_payables, :payables})
      assert_receive {:updated_payables, :payables}
    end
  end

  describe "unsubscribe_from_payables/1" do
    test "unsubscribes from payables for payslip topic" do
      payslip = insert(:payslip)

      payslip_payables_topic =
        "org_id:" <> payslip.org_id <> ":payslip_id:" <> payslip.id <> ":payables"

      org_payables_topic = "org_id:" <> payslip.org_id <> ":payables"

      ####### payslip_payables_topic #######
      @endpoint.subscribe(payslip_payables_topic)

      assert Broadcaster.unsubscribe_from_payables(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, payslip_payables_topic, {:updated_payables, :payables})
      refute_receive {:updated_payables, :payables}

      ####### org_payables_topic #######
      @endpoint.subscribe(org_payables_topic)

      assert Broadcaster.unsubscribe_from_payables(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, org_payables_topic, {:updated_payables, :payables})
      refute_receive {:updated_payables, :payables}
    end

    test "unsubscribes from payables for org topic" do
      payslip = insert(:payslip)

      org_payables_topic = "org_id:" <> payslip.org_id <> ":payables"

      @endpoint.subscribe(org_payables_topic)

      assert Broadcaster.unsubscribe_from_payables(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, org_payables_topic, {:updated_payables, :payables})

      refute_receive {:updated_payables, :payables}
    end
  end

  describe "broadcast_payables_for/1 `%Payslip{}`" do
    test "broadcasts payables from a payslip" do
      org = insert(:org)
      %{id: payslip_id} = payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet,
          org: org,
          target: :payslip,
          due_date: ~D[2021-07-05],
          amount: 100_00
        )

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org =
        insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)

      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      payslip_payables_topic =
        "org_id:" <> payslip.org_id <> ":payslip_id:" <> payslip.id <> ":payables"

      org_payables_topic = "org_id:" <> payslip.org_id <> ":payables"

      ####### payslip_payables_topic #######
      @endpoint.subscribe(payslip_payables_topic)

      assert Broadcaster.broadcast_payables_for(payslip) == :ok

      assert_receive {:updated_payables, {:by_payslip, ^payslip_id},
                      received_payables_for_payslip}

      assert Enum.count(received_payables_for_payslip) == 2

      Enum.each(received_payables_for_payslip, fn payable ->
        assert payable.org_id == org.id
        assert payable.payslip.id == payslip.id
      end)

      @endpoint.unsubscribe(payslip_payables_topic)

      ####### org_payables_topic #######
      @endpoint.subscribe(org_payables_topic)

      assert Broadcaster.broadcast_payables_for(payslip) == :ok

      assert_receive {:updated_payables, {:by_payslip, ^payslip_id},
                      received_payables_for_payslip}

      assert Enum.count(received_payables_for_payslip) == 2

      Enum.each(received_payables_for_payslip, fn payable ->
        assert payable.org_id == org.id
        assert payable.payslip.id == payslip.id
      end)

      @endpoint.unsubscribe(org_payables_topic)
    end
  end

  describe "broadcast_payables_for/1 `%FinancialTransaction{}`" do
    test "broadcasts payables from a financial transaction" do
      org = insert(:org)
      user = insert(:user, org: org)

      financial_transaction = insert(:financial_transaction, org: org, amount: 100_00)

      insert_list(2, :payable_billet,
        org: org,
        amount: 50_00,
        authorized_by: user,
        financial_transaction: financial_transaction
      )

      _to_ignore = insert(:payable_billet)
      _to_ignore = insert(:payable_billet, org: org)

      _to_ignore =
        insert(:payable_billet,
          org: org,
          authorized_by: user,
          financial_transaction: build(:financial_transaction, org: org)
        )

      topic = "org_id:" <> org.id <> ":payables"

      @endpoint.subscribe(topic)

      assert Broadcaster.broadcast_payables_for(financial_transaction) == :ok

      assert_receive {:updated_payables, :by_org, received_payables}

      assert Enum.count(received_payables) == 2

      Enum.each(received_payables, fn payable ->
        assert payable.org_id == org.id
        assert payable.financial_transaction_id == financial_transaction.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_payables/1" do
    test "broadcasts payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet,
          org: org,
          target: :payslip,
          due_date: ~D[2021-07-05],
          amount: 100_00
        )

      payable_cash =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      payable_not_sent =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: payable_not_sent)

      # To ignore
      payable_from_another_org =
        insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)

      insert(:payslip_payable,
        org: payable_from_another_org.org,
        payable: payable_from_another_org
      )

      org_payables_topic = "org_id:" <> payslip.org_id <> ":payables"

      @endpoint.subscribe(org_payables_topic)

      assert Broadcaster.broadcast_payables(org, [
               payable_billet.id,
               payable_cash.id,
               payable_from_another_org.id
             ]) == :ok

      assert_receive {:updated_payables, :by_org, received_payables_for_payslip}

      assert Enum.count(received_payables_for_payslip) == 2

      Enum.each(received_payables_for_payslip, fn payable ->
        assert payable.org_id == org.id
        assert payable.payslip.id == payslip.id
      end)

      @endpoint.unsubscribe(org_payables_topic)
    end
  end

  describe "broadcast_deleted_payable/1" do
    test "broadcasts a deleted payable" do
      %{id: payable_id} = payable = insert(:payable_billet)

      org_payables_topic = "org_id:" <> payable.org_id <> ":payables"

      @endpoint.subscribe(org_payables_topic)

      assert Broadcaster.broadcast_deleted_payable(payable) == :ok

      assert_receive {:deleted_payable, %{id: ^payable_id}}

      @endpoint.unsubscribe(org_payables_topic)
    end
  end
end
