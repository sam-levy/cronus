defmodule Sig.HR.Registrations.Benefits.CreatorTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Benefits.Benefit
  alias Sig.HR.Registrations.Benefits.Creator

  describe "create/3" do
    test "creates a benefit when none exist" do
      registration = insert(:employee_registration)

      attrs = %{
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               description: attrs[:description],
               benefit_type: attrs[:benefit_type],
               is_for_dependent: attrs[:is_for_dependent],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Creator.create(registration, %{})

      assert errors_on(changeset) == %{
               benefit_amount: ["can't be blank"],
               is_for_dependent: ["can't be blank"],
               start_date: ["can't be blank"],
               benefit_type: ["can't be blank"]
             }
    end

    test "fails to insert benefit for employee when existing employee benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      attrs = %{
        benefit_type: :transportation_voucher,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100)
      }

      assert Creator.create(registration, attrs) ==
               {:error, "existe um benefício do mesmo tipo em vigência"}
    end

    test "inserts new benefit for employee when existing employee benefit of different type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        benefit_type: :transportation_voucher,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               is_for_dependent: attrs[:is_for_dependent]
             )
    end

    test "inserts new benefit for employee when existing dependent benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: true,
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "inserts new benefit for dependent when existing employee benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "inserts new benefit for dependent when existing dependent benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: true,
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "fails to insert benefit for employee when existing employee benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: 350_00,
        is_for_dependent: false,
        start_date: ~D[2020-06-01]
      }

      assert Creator.create(registration, attrs) ==
               {:error, "existe um benefício do mesmo tipo em vigência"}
    end

    test "inserts new benefit for empoloyee when existing dependent benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: true,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "inserts new benefit for dependent when existing employee benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "inserts new benefit for dependent when existing dependent benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: true,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "start_date before end_date of the last benefit from the same benefit_type when not for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        benefit_type: :transportation_voucher,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: ~D[2020-01-01]
      }

      assert Creator.create(registration, attrs) ==
               {:error,
                "a data de início deve ser posterior a data de término do último benefício do mesmo tipo"}
    end

    test "start_date before end_date of the last benefit from the same benefit_type when for dependent" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        benefit_type: :health_insurance,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: true,
        start_date: ~D[2020-01-01]
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               start_date: attrs[:start_date]
             )
    end

    test "creates a benefit when others already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # same benefit_type benefit in effect from another company
      insert(:employee_benefit,
        org: org,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      # defferent benefit_type benefit in effect
      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :food_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      # expired benefit from the same benefit_type
      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2019-12-31]
      )

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :transportation_voucher,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      # expired benefit from model of the same benefit_type
      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-12-31]
      )

      attrs = %{
        benefit_type: :transportation_voucher,
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: false,
        start_date: ~D[2021-01-01]
      }

      assert {:ok, %Benefit{id: id}} = Creator.create(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               benefit_type: attrs[:benefit_type],
               benefit_amount: attrs[:benefit_amount],
               is_for_dependent: attrs[:is_for_dependent],
               start_date: attrs[:start_date]
             )
    end
  end

  describe "create_from_model/3" do
    test "creates a benefit from model when none exist" do
      registration = insert(:employee_registration)
      benefit_model = insert(:employee_benefit_model, org: registration.org)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100),
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               description: attrs[:description],
               is_for_dependent: attrs[:is_for_dependent],
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Creator.create_from_model(registration, %{})

      assert errors_on(changeset) == %{
               is_for_dependent: ["can't be blank"],
               start_date: ["can't be blank"],
               benefit_model_id: ["can't be blank"]
             }
    end

    test "fails to insert benefit from model for employee when existing employee benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      benefit_model =
        insert(:employee_benefit_model, org: registration.org, type: :transportation_voucher)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100),
        benefit_model_id: benefit_model.id
      }

      assert Creator.create_from_model(registration, attrs) ==
               {:error, "existe um benefício do mesmo tipo em vigência"}
    end

    test "inserts new benefit from model for employee when existing employee benefit of different type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      benefit_model =
        insert(:employee_benefit_model, org: registration.org, type: :transportation_voucher)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               is_for_dependent: attrs[:is_for_dependent],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "inserts new benefit from model for employee when existing dependent benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: true,
        end_date: nil
      )

      benefit_model =
        insert(:employee_benefit_model, org: registration.org, type: :health_insurance)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: Faker.Date.backward(100),
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "inserts new benefit from model for dependent when existing employee benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: false,
        end_date: nil
      )

      benefit_model =
        insert(:employee_benefit_model, org: registration.org, type: :health_insurance)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100),
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "inserts new benefit from model for dependent when existing dependent benefit of the same type" do
      registration = insert(:employee_registration)

      insert(:employee_benefit,
        org: registration.org,
        registration: registration,
        benefit_type: :health_insurance,
        is_for_dependent: true,
        end_date: nil
      )

      benefit_model =
        insert(:employee_benefit_model, org: registration.org, type: :health_insurance)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: true,
        start_date: Faker.Date.backward(100),
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "fails to insert benefit from model for employee when existing employee benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert Creator.create_from_model(registration, attrs) ==
               {:error, "existe um benefício do mesmo tipo em vigência"}
    end

    test "inserts new benefit from model for empoloyee when existing dependent benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: true,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "inserts new benefit from model for dependent when existing employee benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "inserts new benefit from model for dependent when existing dependent benefit from model of the same type" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :health_insurance,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: true,
        start_date: ~D[2020-01-01],
        end_date: nil
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "start_date before end_date of the last benefit from model of the same type when for employee" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :transportation_voucher,
          amount_date: ~D[2019-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert Creator.create_from_model(registration, attrs) ==
               {:error,
                "a data de início deve ser posterior a data de término do último benefício do mesmo tipo"}
    end

    test "start_date before end_date of the last benefit from model of the same type when for dependent" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :transportation_voucher,
          amount_date: ~D[2019-01-01],
          amount: 300_00
        )

      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: true,
        start_date: ~D[2020-06-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               is_for_dependent: attrs[:is_for_dependent],
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end

    test "creates a benefit from model when others already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # same benefit_type benefit in effect from another company
      insert(:employee_benefit,
        org: org,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      # defferent benefit_type benefit in effect
      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :food_voucher,
        is_for_dependent: false,
        end_date: nil
      )

      # expired benefit of the same benefit_type
      insert(:employee_benefit,
        org: org,
        registration: registration,
        benefit_type: :transportation_voucher,
        is_for_dependent: false,
        start_date: ~D[2019-01-01],
        end_date: ~D[2019-12-31]
      )

      benefit_model =
        insert(:employee_benefit_model,
          org: org,
          type: :transportation_voucher,
          amount_date: ~D[2020-01-01],
          amount: 300_00
        )

      # expired benefit from model of the same benefit_type
      insert(:employee_benefit_from_model,
        org: org,
        registration: registration,
        benefit_model: benefit_model,
        is_for_dependent: false,
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-12-31]
      )

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_for_dependent: false,
        start_date: ~D[2021-01-01],
        benefit_model_id: benefit_model.id
      }

      assert {:ok, %Benefit{id: id}} = Creator.create_from_model(registration, attrs)

      assert Repo.get_by(Benefit,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               is_for_dependent: attrs[:is_for_dependent],
               start_date: attrs[:start_date],
               benefit_model_id: attrs[:benefit_model_id]
             )
    end
  end
end
