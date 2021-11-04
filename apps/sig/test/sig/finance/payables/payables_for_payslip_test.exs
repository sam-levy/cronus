defmodule Sig.Finance.Payables.PayablesForPayslipTest do
  use Sig.DataCase

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.update_change(%Payable{}, %{})
      assert %Ecto.Changeset{data: %Payable{}} = PayablesForPayslip.update_change(%Payable{})
    end
  end

  describe "list_by_payslip/1 for Payslip" do
    test "lists payables from a payslip ordered by due_date" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet, org: org, target: :payslip, due_date: ~D[2021-07-05], amount: 100_00)

      payable_cash = insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org = insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)
      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      assert [
               %Payable{due_date: ~D[2021-06-20]},
               %Payable{due_date: ~D[2021-07-05]}
             ] = PayablesForPayslip.list_by_payslip(payslip)
    end

    test "preloads" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_cash = insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 200_00)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)

      assert [
               %Payable{payslip_payable: %PayslipPayable{}}
             ] = PayablesForPayslip.list_by_payslip(payslip)
    end

    test "when payslip has no payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      assert PayablesForPayslip.list_by_payslip(payslip) == []
    end
  end

  describe "get_by_payslip/2" do
    test "returns a payable" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      assert %Payable{id: ^id} = PayablesForPayslip.get_by_payslip(payslip, id)
    end

    test "when payable belongs to another payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)
      another_payslip = insert(:payslip, org: org, amount: 0)

      %{id: id} = payable = insert(:payable_cash, org: org, target: :payslip, amount: 0)
      insert(:payslip_payable, org: org, payslip: another_payslip, payable: payable)

      assert PayablesForPayslip.get_by_payslip(payslip, id) == nil
    end

    test "when payable doesn't exist" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, amount: 0)

      assert PayablesForPayslip.get_by_payslip(payslip, UUID.generate()) == nil
    end
  end

  describe "subscribe_to_payables_for_payslip/1" do
    test "subscribes to payables for payslip topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":payables"

      assert PayablesForPayslip.subscribe_to_payables_for_payslip(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payables_for_payslip, :payables})

      assert_receive {:updated_payables_for_payslip, :payables}
    end
  end

  describe "unsubscribe_from_payables_for_payslip/1" do
    test "unsubscribes from payables for payslip topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":payables"

      @endpoint.subscribe(topic)

      assert PayablesForPayslip.unsubscribe_from_payables_for_payslip(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payables_for_payslip, :payables})

      refute_receive {:updated_payables_for_payslip, :payables}
    end
  end

  describe "broadcast_payables_for_payslip/1" do
    test "broadcasts payables from a payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_entry_type: :credit,
        amount: 200_00
      )

      # Update payslip amount
      Repo.update!(change(payslip, amount: 200_00))

      payable_billet =
        insert(:payable_billet, org: org, target: :payslip, due_date: ~D[2021-07-05], amount: 100_00)

      payable_cash = insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-06-20], amount: 100_00)

      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_cash)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable_billet)

      # To ignore
      from_another_payslip =
        insert(:payable_cash, org: org, target: :payslip, due_date: ~D[2021-08-01], amount: 0)

      insert(:payslip_payable, org: org, payable: from_another_payslip)

      # To ignore
      from_another_org = insert(:payable_cash, target: :payslip, due_date: ~D[2021-09-01], amount: 0)
      insert(:payslip_payable, org: from_another_org.org, payable: from_another_org)

      topic = "payslip_id:" <> payslip.id <> ":payables"

      @endpoint.subscribe(topic)

      assert PayablesForPayslip.broadcast_payables_for_payslip(payslip) == :ok

      assert_receive {:updated_payables_for_payslip, received_payables_for_payslip}

      assert Enum.count(received_payables_for_payslip) == 2

      Enum.each(received_payables_for_payslip, fn payable ->
        assert payable.org_id == org.id
        assert payable.payslip_payable.payslip_id == payslip.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
