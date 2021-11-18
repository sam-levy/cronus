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

  describe "toggle_is_closed/2" do
    test "toggles is_closed when false" do
      %{id: id} = payslip = insert(:payslip, is_closed: false)

      assert {:ok, %Payslip{id: ^id, is_closed: true}} = Payslips.toggle_is_closed(payslip)

      assert Repo.get_by(Payslip, org_id: payslip.org_id, id: id, is_closed: true)
    end

    test "toggles is_closed when true" do
      %{id: id} = payslip = insert(:payslip, is_closed: true)

      assert {:ok, %Payslip{id: ^id, is_closed: false}} = Payslips.toggle_is_closed(payslip)

      assert Repo.get_by(Payslip, org_id: payslip.org_id, id: id, is_closed: false)
    end
  end

  describe "update_payslip_amount/2" do
    test "updates the amount of the payslip based on the payslip items" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO"
        )

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_category,
          amount: Money.new(1_000_00)
        )

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_advance_category,
          amount: Money.new(400_00),
          is_payment_advance: true
        )

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      health_insurance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: health_insurance_category,
          amount: Money.new(300_00)
        )

      salary_supplement_item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          description: "Complemento Salário",
          entry_type: :credit,
          amount: Money.new(200_00)
        )

      # Item from another payslip to be ignored
      to_ignore =
        insert(:payslip_outside_item,
          org: org,
          description: "Complemento Salário",
          entry_type: :credit,
          amount: Money.new(150_00)
        )

      items = [
        salary_item,
        payment_advance_item,
        health_insurance_item,
        salary_supplement_item,
        to_ignore
      ]

      assert {:ok, %Payslip{amount: %Money{amount: 500_00}}} =
               Payslips.update_payslip_amount(payslip, items)
    end

    test "when items brings the payslip amount to negative" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO"
        )

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_category,
          amount: Money.new(1_000_00)
        )

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_advance_category,
          amount: Money.new(1_100_00),
          is_payment_advance: true
        )

      items = [salary_item, payment_advance_item]

      assert Payslips.update_payslip_amount(payslip, items) ==
               {:error, "payslip amount can't be negative"}
    end

    test "when items brings the payslip amount to zero" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO"
        )

      salary_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_category,
          amount: Money.new(1_000_00)
        )

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      payment_advance_item =
        insert(:payslip_item,
          org: org,
          payslip: payslip,
          category: salary_advance_category,
          amount: Money.new(1_000_00),
          is_payment_advance: true
        )

      items = [salary_item, payment_advance_item]

      assert {:ok, %Payslip{amount: %Money{amount: 0_00}}} =
               Payslips.update_payslip_amount(payslip, items)
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

  describe "broadcast_deleted_registration_payslip/1" do
    test "broadcasts a deleted payslip from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      payslip = insert(:payslip, org: org, registration: registration)

      topic = "registration_id:" <> registration.id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_deleted_registration_payslip(registration, payslip) == :ok

      assert_receive {:deleted_payslip, ^payslip}

      @endpoint.unsubscribe(topic)
    end
  end

  describe "subscribe_to_payslip/1" do
    test "subscribes to a payslip topic" do
      payslip = insert(:payslip)

      topic = "payslip_id:" <> payslip.id

      assert Payslips.subscribe_to_payslip(payslip) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_payslip, :payslip}
      )

      assert_receive {:updated_payslip, :payslip}
    end
  end

  describe "broadcast_updated_registration_payslip/2" do
    test "broadcasts a payslip" do
      payslip = insert(:payslip)

      topic = "registration_id:" <> payslip.registration_id <> ":payslips"

      @endpoint.subscribe(topic)

      assert Payslips.broadcast_updated_registration_payslip(payslip) == :ok

      assert_receive {:updated_payslip, received_payslip}

      assert received_payslip.id == payslip.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "unsubscribe_from_payslip/1" do
    test "unsubscribes from a payslip topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id

      @endpoint.subscribe(topic)

      assert Payslips.unsubscribe_from_payslip(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payslip, :payslip})

      refute_receive {:updated_payslip, :payslip}
    end
  end
end
