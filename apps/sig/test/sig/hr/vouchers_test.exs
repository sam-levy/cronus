defmodule Sig.HR.Registrations.VouchersTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Vouchers
  alias Sig.HR.Registrations.Vouchers.Voucher

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Voucher{}} = Vouchers.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Voucher{}} = Vouchers.update_change(%Voucher{}, %{})
      assert %Ecto.Changeset{data: %Voucher{}} = Vouchers.update_change(%Voucher{})
    end
  end

  describe "list_voucher_types/0" do
    test "lists voucher types" do
      assert Vouchers.list_voucher_types() == [
               "transport",
               "meal",
               "food",
               "employee_health_insurance",
               "employee_dependents_health_insurance"
             ]
    end
  end

  describe "get/2" do
    test "gets a voucher" do
      registration = insert(:employee_registration)
      %{id: id} = insert(:employee_voucher, org: registration.org, registration: registration)

      assert %Voucher{id: ^id} = Vouchers.get(registration, id)
    end

    test "voucher from another registration" do
      org = insert(:org)
      registration_1 = insert(:employee_registration, org: org)
      registration_2 = insert(:employee_registration, org: org)

      voucher = insert(:employee_voucher, org: org, registration: registration_1)

      assert Vouchers.get(registration_2, voucher.id) == nil
    end

    test "voucher doesn't exist" do
      registration = insert(:employee_registration)

      assert Vouchers.get(registration, UUID.generate()) == nil
    end
  end

  describe "list_by_registration/1" do
    test "lists vouchers by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :transport,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :meal,
        start_date: ~D[2020-06-01]
      )

      assert [
               %Voucher{start_date: ~D[2020-01-01]},
               %Voucher{start_date: ~D[2020-06-01]}
             ] = Vouchers.list_by_registration(registration)
    end

    test "registration has no voucher" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert Vouchers.list_by_registration(registration) == []
    end
  end

  describe "update/2" do
    test "updates a voucher" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{end_date: ~D[2021-01-01]}

      assert {:ok, _return} = Vouchers.update(voucher, attrs)

      assert Repo.get_by(Voucher,
               id: voucher.id,
               org_id: voucher.org_id,
               registration_id: voucher.registration_id,
               end_date: attrs[:end_date]
             )
    end

    test "changeset errors" do
      voucher = insert(:employee_voucher)

      assert {:error, changeset} = Vouchers.update(voucher, %{})

      assert errors_on(changeset) == %{end_date: ["can't be blank"]}
    end
  end

  describe "subscribe_to_registration_vouchers/1" do
    test "subscribes to registration vouchers topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":vouchers"

      assert Vouchers.subscribe_to_registration_vouchers(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_vouchers, :vouchers}
      )

      assert_receive {:updated_registration_vouchers, :vouchers}
    end
  end

  describe "broadcast_registration_vouchers/1" do
    test "broadcasts vouchers from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_voucher, type: :transport, org: org, registration: registration)
      insert(:employee_voucher, type: :meal, org: org, registration: registration)

      insert(:employee_voucher, type: :transport)
      insert(:employee_voucher, type: :meal)

      topic = "registration_id:" <> registration.id <> ":vouchers"

      @endpoint.subscribe(topic)

      assert Vouchers.broadcast_registration_vouchers(registration) == :ok

      assert_receive {:updated_registration_vouchers, received_vouchers}

      assert Enum.count(received_vouchers) == 2

      Enum.each(received_vouchers, fn voucher ->
        assert voucher.org_id == org.id
        assert voucher.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
