defmodule Sig.HR.PayslipsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payslip{}} = Payslips.create_change()
    end
  end

  describe "list_by_registration/1" do
    test "lists payslips by registration ordered by decending start date" do
      registration = insert(:employee_registration)

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-02-01]
      )

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      assert [
               %Payslip{start_date: ~D[2021-02-01]},
               %Payslip{start_date: ~D[2021-01-01]}
             ] = Payslips.list_by_registration(registration)
    end

    test "registration has no payslips" do
      registration = insert(:employee_registration)

      assert Payslips.list_by_registration(registration) == []
    end
  end

  describe "get/2" do
    test "returns a payslip" do
      registration = insert(:employee_registration)

      %{id: id} = insert(:payslip, org: registration.org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get(registration, id)
    end

    test "payslip belongs to another registration" do
      registration = insert(:employee_registration)
      another_registration = insert(:employee_registration)

      %{id: id} =
        insert(:payslip, org: another_registration.org, registration: another_registration)

      assert Payslips.get(registration, id) == nil
    end

    test "payslip doesn't exist" do
      registration = insert(:employee_registration)

      assert Payslips.get(registration, UUID.generate()) == nil
    end
  end

  describe "get_by/2" do
    test "returns a payslip by attrs" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} = insert(:payslip, org: org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get_by(id: id, org_id: org.id)
    end

    test "when field does't exist" do
      org = insert(:org)

      assert Payslips.get_by(id: UUID.generate(), org_id: org.id) == nil
    end
  end

  describe "subscribe_to_registration_payslips/1" do
    test "subscribes to registration payslips topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":payslips"

      assert Payslips.subscribe_to_registration_payslips(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_payslips, :payslips}
      )

      assert_receive {:updated_registration_payslips, :payslips}
    end
  end

  describe "broadcast_registration_payslips/1" do
    test "broadcasts payslips from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:payslip, org: org, registration: registration)
      insert(:payslip, org: org, registration: registration)

      insert(:payslip, org: org)

      topic = "registration_id:" <> registration.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_registration_payslips(registration) == :ok

      assert_receive {:updated_registration_payslips, received_payslips}

      assert Enum.count(received_payslips) == 2

      Enum.each(received_payslips, fn payslip ->
        assert payslip.org_id == org.id
        assert payslip.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
