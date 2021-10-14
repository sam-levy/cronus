defmodule Sig.HR.Registrations.VouchersTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Benefits
  alias Sig.HR.Registrations.Benefits.Benefit

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.update_change(%Benefit{}, %{})
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.update_change(%Benefit{})
    end
  end

  describe "list_benefit_types/0" do
    test "lists benefit types" do
      assert Benefits.list_benefit_types() == [
               "meal_voucher",
               "food_voucher",
               "transportation_voucher",
               "health_insurance"
             ]
    end
  end

  describe "get/2" do
    test "gets a benefit" do
      registration = insert(:employee_registration)
      %{id: id} = insert(:employee_benefit, org: registration.org, registration: registration)

      assert %Benefit{id: ^id} = Benefits.get(registration, id)
    end

    test "benefit from another registration" do
      org = insert(:org)
      registration_1 = insert(:employee_registration, org: org)
      registration_2 = insert(:employee_registration, org: org)

      benefit = insert(:employee_benefit, org: org, registration: registration_1)

      assert Benefits.get(registration_2, benefit.id) == nil
    end

    test "benefit doesn't exist" do
      registration = insert(:employee_registration)

      assert Benefits.get(registration, UUID.generate()) == nil
    end
  end

  describe "list_by_registration/1" do
    test "lists benefits by registration ordered by start_date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :meal_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      assert [
               %Benefit{start_date: ~D[2020-01-01]},
               %Benefit{start_date: ~D[2020-06-01]}
             ] = Benefits.list_by_registration(registration)
    end

    test "lists benefits by registration ordered by start_date filtered by types" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :meal_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        is_for_dependent: false,
        amount: 300_00,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 350_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-02]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 360_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-03]
      )

      assert [
               %Benefit{amount: %Money{amount: 300_00}, start_date: ~D[2020-06-01]},
               %Benefit{amount: %Money{amount: 350_00}, start_date: ~D[2020-06-02]},
               %Benefit{amount: %Money{amount: 360_00}, start_date: ~D[2020-06-03]}
             ] =
               Benefits.list_by_registration(registration,
                 types: [:health_insurance, :health_insurance]
               )
    end

    test "when benefit from a type does't exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      assert Benefits.list_by_registration(registration, types: [:health_insurance]) ==
               []
    end

    test "when types opts is empty " do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      assert Benefits.list_by_registration(registration, types: []) == []
    end

    test "in_effect_on_date filter" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        amount: 500_00,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 300_00,
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 320_00,
        is_for_dependent: false,
        start_date: ~D[2021-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 250_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 260_00,
        is_for_dependent: true,
        start_date: ~D[2021-01-02]
      )

      assert [
               %Benefit{amount: %Money{amount: 500_00}, start_date: ~D[2020-01-01]},
               %Benefit{amount: %Money{amount: 320_00}, start_date: ~D[2021-01-01]},
               %Benefit{amount: %Money{amount: 260_00}, start_date: ~D[2021-01-02]}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2021-07-01])
    end

    test "types and in_effect_on_date filters combined" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 300_00,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 350_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 370_00,
        is_for_dependent: true,
        start_date: ~D[2021-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :health_insurance,
        amount: 360_00,
        is_for_dependent: true,
        start_date: ~D[2021-08-01]
      )

      assert [
               %Benefit{amount: %Money{amount: 300_00}},
               %Benefit{amount: %Money{amount: 370_00}}
             ] =
               Benefits.list_by_registration(registration,
                 types: [:health_insurance, :health_insurance],
                 in_effect_on_date: ~D[2021-07-01]
               )
    end

    test "registration has no benefit" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assert Benefits.list_by_registration(registration) == []
    end
  end

  describe "update/2" do
    test "updates a benefit" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{end_date: ~D[2021-01-01]}

      assert {:ok, _return} = Benefits.update(benefit, attrs)

      assert Repo.get_by(Benefit,
               id: benefit.id,
               org_id: benefit.org_id,
               registration_id: benefit.registration_id,
               end_date: attrs[:end_date]
             )
    end

    test "changeset errors" do
      benefit = insert(:employee_benefit)

      assert {:error, changeset} = Benefits.update(benefit, %{})

      assert errors_on(changeset) == %{end_date: ["can't be blank"]}
    end
  end

  describe "subscribe_to_registration_benefits/1" do
    test "subscribes to registration benefits topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":benefits"

      assert Benefits.subscribe_to_registration_benefits(registration) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_benefits, :benefits}
      )

      assert_receive {:updated_registration_benefits, :benefits}
    end
  end

  describe "broadcast_registration_benefits/1" do
    test "broadcasts benefits from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false
      )

      insert(:employee_benefit, type: :meal_voucher, is_for_dependent: false, org: org, registration: registration)

      insert(:employee_benefit, type: :transportation_voucher, is_for_dependent: false)
      insert(:employee_benefit, type: :meal_voucher, is_for_dependent: false)

      topic = "registration_id:" <> registration.id <> ":benefits"

      @endpoint.subscribe(topic)

      assert Benefits.broadcast_registration_benefits(registration) == :ok

      assert_receive {:updated_registration_benefits, received_benefits}

      assert Enum.count(received_benefits) == 2

      Enum.each(received_benefits, fn benefit ->
        assert benefit.org_id == org.id
        assert benefit.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
