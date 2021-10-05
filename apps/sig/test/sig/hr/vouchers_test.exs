defmodule Sig.HR.Registrations.VouchersTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Vouchers
  alias Sig.HR.Registrations.Vouchers.Voucher

  @endpoint SigLive.Endpoint

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

      _right_vouchers =
        insert_list(2, :employee_voucher, org: org, registration: registration)

      _wrong_vouchers = insert_list(2, :employee_voucher)

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
