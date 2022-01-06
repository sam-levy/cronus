defmodule Sig.Finance.Payables.BroadcasterTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Broadcaster

  @endpoint SigLive.Endpoint

  describe "subscribe_to_payables/1" do
    test "subscribes to payables for payslip topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":payables"

      assert Broadcaster.subscribe_to_payables(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payables, :payables})

      assert_receive {:updated_payables, :payables}
    end
  end

  describe "unsubscribe_from_payables/1" do
    test "unsubscribes from payables for payslip topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":payables"

      @endpoint.subscribe(topic)

      assert Broadcaster.unsubscribe_from_payables(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payables, :payables})

      refute_receive {:updated_payables, :payables}
    end
  end

  describe "broadcast_updated_payables/1" do
    test "broadcasts payables from a payslip" do
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
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org =
        insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)

      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      topic = "payslip_id:" <> payslip.id <> ":payables"

      @endpoint.subscribe(topic)

      assert Broadcaster.broadcast_updated_payables(payslip) == :ok

      assert_receive {:updated_payables, received_payables_for_payslip}

      assert Enum.count(received_payables_for_payslip) == 2

      Enum.each(received_payables_for_payslip, fn payable ->
        assert payable.org_id == org.id
        assert payable.payslip_payable.payslip_id == payslip.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end

end
