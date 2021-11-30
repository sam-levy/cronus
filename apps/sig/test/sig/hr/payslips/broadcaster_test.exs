defmodule Sig.HR.Payslips.BroadcasterTest do
  use Sig.DataCase

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip

  @endpoint SigLive.Endpoint

  describe "subscribe_to_payslips/1" do
    test "subscribes to registration payslips topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":payslips"

      assert Payslips.subscribe_to_payslips(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_payslips, :payslips}
      )

      assert_receive {:updated_registration_payslips, :payslips}
    end

    test "subscribes to group payslips topic" do
      group = insert(:payslip_group)
      topic = "group_id:" <> group.id <> ":payslips"

      assert Payslips.subscribe_to_payslips(group) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_payslips, :payslips}
      )

      assert_receive {:updated_registration_payslips, :payslips}
    end
  end

  describe "broadcast_new_payslip/1" do
    test "broadcasts payslip" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)
      registration = insert(:employee_registration, org: org)

      %{id: id} =
        payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date
        )

      topic = "group_id:" <> group.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_new_payslip(payslip) == :ok

      assert_receive {:new_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)

      topic = "registration_id:" <> registration.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_new_payslip(payslip) == :ok

      assert_receive {:new_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_payslip/1" do
    test "broadcasts payslip" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)
      registration = insert(:employee_registration, org: org)

      %{id: id} =
        payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date
        )

      topic = "group_id:" <> group.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_deleted_payslip(payslip) == :ok

      assert_receive {:deleted_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)

      topic = "registration_id:" <> registration.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_deleted_payslip(payslip) == :ok

      assert_receive {:deleted_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_payslip/1" do
    test "broadcasts payslip when group_id is the same" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)
      registration = insert(:employee_registration, org: org)

      %{id: id} =
        payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date
        )

      topic = "group_id:" <> group.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_updated_payslip(payslip, nil) == :ok

      assert_receive {:updated_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)

      topic = "registration_id:" <> registration.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_updated_payslip(payslip, nil) == :ok

      assert_receive {:updated_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(topic)
    end

    test "broadcasts payslip when group_id is different" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      regular_group = insert(:payslip_group, org: org, type: type, date: start_date)
      vacation_group = insert(:payslip_group, org: org, type: :vacation, date: start_date)

      registration = insert(:employee_registration, org: org)

      %{id: id} =
        old_payslip =
        insert(:payslip,
          org: org,
          group: regular_group,
          registration: registration,
          type: type,
          start_date: start_date
        )

      updated_payslip =
        Repo.update!(change(old_payslip, type: :vacation, group_id: vacation_group.id))

      regular_group_topic = "group_id:" <> regular_group.id <> ":payslips"
      vacation_group_topic = "group_id:" <> vacation_group.id <> ":payslips"

      @endpoint.subscribe(regular_group_topic)
      @endpoint.subscribe(vacation_group_topic)

      assert Payslips.broadcast_updated_payslip(updated_payslip, old_payslip) == :ok

      assert_receive {:updated_payslip, %Payslip{id: ^id}}
      assert_receive {:updated_payslip, %Payslip{id: ^id}}

      @endpoint.unsubscribe(regular_group_topic)
      @endpoint.unsubscribe(vacation_group_topic)
    end
  end

  describe "unsubscribe_from_payslip/1" do
    test "unsubscribes from a payslip topic" do
      org = insert(:org)
      type = :regular
      start_date = ~D[2021-01-01]

      group = insert(:payslip_group, org: org, type: type, date: start_date)
      registration = insert(:employee_registration, org: org)

      payslip =
        insert(:payslip,
          org: org,
          group: group,
          registration: registration,
          type: type,
          start_date: start_date
        )

      registration_topic = "registration_id:" <> registration.id <> ":payslips"
      group_topic = "group_id:" <> group.id <> ":payslips"

      @endpoint.subscribe(registration_topic)
      @endpoint.subscribe(group_topic)

      assert Payslips.unsubscribe_from_payslip(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, registration_topic, {:updated_payslip, :payslip})
      Phoenix.PubSub.broadcast(Sig.PubSub, group_topic, {:updated_payslip, :payslip})

      refute_receive {:updated_payslip, :payslip}
      refute_receive {:updated_payslip, :payslip}
    end
  end
end
