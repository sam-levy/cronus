defmodule Sig.HR.Registrations.Benefits.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.HR.Registrations.Benefits.Create

  describe "call/3" do
    test "creates a benefit when none exist" do
      registration = insert(:employee_registration)

      attrs = %{
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        is_for_dependent: Enum.random([true, false]),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               description: attrs[:description],
               type: attrs[:type],
               is_for_dependent: attrs[:is_for_dependent],
               amount: attrs[:amount],
               start_date: attrs[:start_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Create.call(registration, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               is_for_dependent: ["can't be blank"],
               start_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "same type benefit in effect when not for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      attrs = %{
        type: :transportation_voucher,
        amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100)
      }

      assert Create.call(registration, attrs) ==
               {:error, "existe um vale do mesmo tipo em vigência"}
    end

    test "same type benefit in effect when for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        type: :employee_dependents_health_insurance,
        is_for_dependent: false,
        end_date: nil
      )

      attrs = %{
        type: :employee_dependents_health_insurance,
        amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               amount: attrs[:amount],
               start_date: attrs[:start_date]
             )
    end

    test "start_date before end_date of the last benefit from the same type when not for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        type: :transportation_voucher,
        amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      }

      assert Create.call(registration, attrs) ==
               {:error,
                "a data de início deve ser posterior a data de término do último vale do mesmo tipo"}
    end

    test "start_date before end_date of the last benefit from the same type when for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        type: :employee_dependents_health_insurance,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        type: :employee_dependents_health_insurance,
        amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: ~D[2020-01-01]
      }

      assert {:ok, %Benefit{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               amount: attrs[:amount],
               start_date: attrs[:start_date]
             )
    end

    test "creates a benefit when others already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # defferent type benefit in effect
      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :food_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      # expired benefit from the same type
      insert(:employee_benefit,
        org: org,
        registration: registration,
        type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      # same type benefit in effect from another company
      insert(:employee_benefit,
        org: org,
        type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      attrs = %{
        type: :transportation_voucher,
        amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: ~D[2021-01-02]
      }

      assert {:ok, %Benefit{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               amount: attrs[:amount],
               is_for_dependent: attrs[:is_for_dependent],
               start_date: attrs[:start_date]
             )
    end
  end
end
