defmodule Sig.HR.Registrations.BenefitsTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Benefits
  alias Sig.HR.Registrations.Benefits.Benefit

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.create_change()
    end
  end

  describe "create_from_model_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.create_from_model_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.update_change(%Benefit{}, %{})
      assert %Ecto.Changeset{data: %Benefit{}} = Benefits.update_change(%Benefit{})
    end
  end

  describe "get/2" do
    test "gets a benefit" do
      registration = insert(:employee_registration)
      %{id: id} = insert(:employee_benefit, org: registration.org, registration: registration)

      assert %Benefit{id: ^id} = Benefits.get(registration, id)
    end

    test "fills virtual fields for is_from_model false benefit" do
      registration = insert(:employee_registration)

      benefit =
        insert(:employee_benefit,
          org: registration.org,
          registration: registration,
          is_from_model: false,
          benefit_type: random_enum_value(:employee_benefit_type),
          benefit_amount: Enum.random(400_00..600_00)
        )

      assert return = Benefits.get(registration, benefit.id)

      assert return.id == benefit.id
      assert return.type == benefit.benefit_type
      assert return.amount == %Money{amount: benefit.benefit_amount, currency: :BRL}
    end

    test "fills virtual fields for is_from_model true benefit" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      benefit_model = insert(:employee_benefit_model, org: org)

      benefit =
        insert(:employee_benefit_from_model,
          org: registration.org,
          registration: registration,
          is_from_model: true,
          benefit_model: benefit_model
        )

      assert return = Benefits.get(registration, benefit.id)

      assert return.id == benefit.id
      assert return.type == benefit_model.type
      assert return.amount == %Money{amount: benefit_model.amount, currency: :BRL}
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
        type: :meal_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      assert [
               %Benefit{start_date: ~D[2020-01-01]},
               %Benefit{start_date: ~D[2020-06-01]}
             ] = Benefits.list_by_registration(registration)
    end

    test "fill virtual fields" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model, org: org, type: :health_insurance, amount: 300_00)

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-01],
        benefit_model: benefit_model
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        start_date: ~D[2020-01-01],
        is_from_model: false,
        benefit_type: :transportation_voucher,
        benefit_amount: 200_00
      )

      assert [
               %Benefit{
                 start_date: ~D[2020-01-01],
                 type: :transportation_voucher,
                 amount: %Money{amount: 200_00}
               },
               %Benefit{
                 start_date: ~D[2020-06-01],
                 type: :health_insurance,
                 amount: %Money{amount: 300_00}
               }
             ] = Benefits.list_by_registration(registration)
    end

    test "lists benefits by registration ordered by start_date filtered by types" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      health_insurance_benefit_model =
        insert(:employee_benefit_model, org: org, type: :health_insurance, amount: 301_00)

      food_voucher_benefit_model =
        insert(:employee_benefit_model, org: org, type: :food_voucher, amount: 201_00)

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        is_for_dependent: true,
        start_date: ~D[2020-06-04],
        benefit_model: health_insurance_benefit_model
      )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        is_for_dependent: true,
        start_date: ~D[2020-06-05],
        benefit_model: food_voucher_benefit_model
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
        benefit_amount: 300_00,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :meal_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        benefit_amount: 300_00,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 350_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-02]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 360_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-03]
      )

      assert [
               %Benefit{
                 amount: %Money{amount: 300_00},
                 start_date: ~D[2020-01-01],
                 type: :transportation_voucher
               },
               %Benefit{
                 amount: %Money{amount: 300_00},
                 start_date: ~D[2020-06-01],
                 type: :health_insurance
               },
               %Benefit{
                 amount: %Money{amount: 350_00},
                 start_date: ~D[2020-06-02],
                 type: :health_insurance
               },
               %Benefit{
                 amount: %Money{amount: 360_00},
                 start_date: ~D[2020-06-03],
                 type: :health_insurance
               },
               %Benefit{
                 amount: %Money{amount: 301_00},
                 start_date: ~D[2020-06-04],
                 type: :health_insurance
               }
             ] =
               Benefits.list_by_registration(registration,
                 types: [:health_insurance, :transportation_voucher]
               )
    end

    test "when benefit from a type does't exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      assert Benefits.list_by_registration(registration, types: [:health_insurance]) ==
               []
    end

    test "when types opts is empty " do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model = insert(:employee_benefit_model, org: org, type: :food_voucher)

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-04],
        benefit_model: benefit_model
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
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
        benefit_type: :transportation_voucher,
        benefit_amount: 500_00,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 300_00,
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 320_00,
        is_for_dependent: false,
        start_date: ~D[2021-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 250_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 260_00,
        is_for_dependent: true,
        start_date: ~D[2021-01-02]
      )

      assert [
               %Benefit{amount: %Money{amount: 500_00}, start_date: ~D[2020-01-01]},
               %Benefit{amount: %Money{amount: 320_00}, start_date: ~D[2021-01-01]},
               %Benefit{amount: %Money{amount: 260_00}, start_date: ~D[2021-01-02]}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2021-07-01])
    end

    test "in_effect_on_date filter for historical amounts" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      historical_amounts = [
        build(:historical_amount, date: ~D[2021-01-01], amount: %Money{amount: 300_00}),
        build(:historical_amount, date: ~D[2020-06-01], amount: %Money{amount: 200_00}),
        build(:historical_amount, date: ~D[2020-01-01], amount: %Money{amount: 100_00})
      ]

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :food_voucher,
          amount_date: ~D[2021-01-01],
          amount: 300_00,
          historical_amounts: historical_amounts
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        is_for_dependent: true,
        start_date: ~D[2020-04-01],
        benefit_model: benefit_model
      )

      assert [
               %Benefit{amount: %Money{amount: 300_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2021-07-01])

      assert [
               %Benefit{amount: %Money{amount: 200_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2020-06-02])

      assert [
               %Benefit{amount: %Money{amount: 200_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2020-06-01])

      assert [
               %Benefit{amount: %Money{amount: 100_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2020-05-31])

      assert [
               %Benefit{amount: %Money{amount: 300_00}}
             ] = Benefits.list_by_registration(registration)

      assert Benefits.list_by_registration(registration, in_effect_on_date: ~D[2019-12-31]) == []
    end

    test "in_effect_on_date filter for historical amounts with is_from_model true benefits" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      historical_amounts = [
        build(:historical_amount, date: ~D[2021-01-01], amount: %Money{amount: 300_00}),
        build(:historical_amount, date: ~D[2020-06-01], amount: %Money{amount: 200_00}),
        build(:historical_amount, date: ~D[2020-01-01], amount: %Money{amount: 100_00})
      ]

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :food_voucher,
          amount_date: ~D[2021-01-01],
          amount: 300_00,
          historical_amounts: historical_amounts
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        is_for_dependent: true,
        start_date: ~D[2020-04-01],
        benefit_model: benefit_model
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31],
        benefit_amount: 50_00
      )

      assert [
               %Benefit{amount: %Money{amount: 300_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2021-07-01])

      assert [
               %Benefit{amount: %Money{amount: 200_00}},
               %Benefit{amount: %Money{amount: 50_00}}
             ] = Benefits.list_by_registration(registration, in_effect_on_date: ~D[2020-06-02])
    end

    test "types and in_effect_on_date filters combined" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 300_00,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 350_00,
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        end_date: ~D[2020-12-31]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 370_00,
        is_for_dependent: true,
        start_date: ~D[2021-01-01]
      )

      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :health_insurance,
        benefit_amount: 360_00,
        is_for_dependent: true,
        start_date: ~D[2021-08-01]
      )

      assert [
               %Benefit{amount: %Money{amount: 300_00}},
               %Benefit{amount: %Money{amount: 370_00}}
             ] =
               Benefits.list_by_registration(registration,
                 types: [:health_insurance],
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

      insert(:employee_benefit,
        type: :meal_voucher,
        is_for_dependent: false,
        org: org,
        registration: registration
      )

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
