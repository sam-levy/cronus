defmodule Sig.HR.Registrations.Benefits.BenefitTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Benefits.Benefit

  describe "employee_benefits table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_benefits\" violates not-null constraint/,
                   fn -> Repo.insert(benefit) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: UUID.generate(),
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefits_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      benefit = %Benefit{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_benefits\" violates not-null constraint/,
                   fn -> Repo.insert(benefit) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      benefit = %Benefit{
        org_id: org.id,
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefits_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "employee_benefits_amount_greater_than_zero constraint" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: -1,
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefits_amount_greater_than_zero \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "employee_benefits_start_date_before_end_date constraint" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: ~D[2021-01-01],
        end_date: ~D[2020-01-01]
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_benefits_start_date_before_end_date \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end
  end

  describe "employee_benefits table is_from_model false conditional constraints" do
    test "benefit_amount is null" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise  Ecto.ConstraintError,
                   ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "benefit_type is null" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert_raise  Ecto.ConstraintError,
                   ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "benefit_model_id is not null" do
      registration = insert(:employee_registration)
      employee_benefit_model = insert(:employee_benefit_model, org: registration.org)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100),
        benefit_model_id: employee_benefit_model.id
      }

      assert_raise  Ecto.ConstraintError,
                   ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "insert" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: false,
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, _return} = Repo.insert(benefit)
    end
  end

  describe "employee_benefits table is_from_model true conditional constraints" do
    test "benefit_amount is not null" do
      registration = insert(:employee_registration)
      employee_benefit_model = insert(:employee_benefit_model, org: registration.org)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: true,
        start_date: Faker.Date.backward(100),
        benefit_model_id: employee_benefit_model.id
      }

      assert_raise  Ecto.ConstraintError,
                   ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                   fn -> Repo.insert(benefit) end
    end

    test "benefit_type is not null" do
      registration = insert(:employee_registration)
      employee_benefit_model = insert(:employee_benefit_model, org: registration.org)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: true,
        start_date: Faker.Date.backward(100),
        benefit_model_id: employee_benefit_model.id
      }

      assert_raise  Ecto.ConstraintError,
                  ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                  fn -> Repo.insert(benefit) end
    end

    test "benefit_model_id is null" do
      registration = insert(:employee_registration)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: true,
        start_date: Faker.Date.backward(100),
      }

      assert_raise  Ecto.ConstraintError,
                  ~r/employee_benefits_is_from_model_conditional \(check_constraint\)/,
                  fn -> Repo.insert(benefit) end
    end

    test "insert" do
      registration = insert(:employee_registration)
      employee_benefit_model = insert(:employee_benefit_model, org: registration.org)

      benefit = %Benefit{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        is_for_dependent: Enum.random([true, false]),
        is_from_model: true,
        start_date: Faker.Date.backward(100),
        benefit_model_id: employee_benefit_model.id
      }

      assert {:ok, _return} = Repo.insert(benefit)
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100)
      }

      assert changeset = Benefit.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        description: attrs[:description],
        benefit_type: attrs[:benefit_type],
        benefit_amount: %Money{amount: attrs[:benefit_amount], currency: :BRL},
        is_for_dependent: attrs[:is_for_dependent],
        start_date: attrs[:start_date],
        is_from_model: false
      }
    end

    test "missing required attrs" do
      assert changeset = Benefit.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
        benefit_amount: ["can't be blank"],
        org_id: ["can't be blank"],
        registration_id: ["can't be blank"],
        is_for_dependent: ["can't be blank"],
        start_date: ["can't be blank"],
        benefit_type: ["can't be blank"]
      }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        benefit_type: :invalid,
        benefit_amount: :invalid,
        is_for_dependent: :invalid,
        start_date: :invalid
      }

      assert changeset = Benefit.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        org_id: ["is invalid"],
        registration_id: ["is invalid"],
        benefit_type: ["is invalid"],
        benefit_amount: ["is invalid"],
        is_for_dependent: ["is invalid"],
        start_date: ["is invalid"]
      }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100),
        is_from_model: true,
        end_date: Faker.Date.backward(1),
        benefit_model_id: UUID.generate()
      }

      assert changeset = Benefit.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        description: attrs[:description],
        is_for_dependent: attrs[:is_for_dependent],
        benefit_amount: %Money{amount: attrs[:benefit_amount], currency: :BRL},
        benefit_type: attrs[:benefit_type],
        start_date: attrs[:start_date],
        is_from_model: false
      }
    end

    test "negative benefit_amount" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        is_for_dependent: Enum.random([true, false]),
        benefit_amount: -1,
        start_date: Faker.Date.backward(100)
      }

      assert changeset = Benefit.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{benefit_amount: ["must be greater than 0,00"]}
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: String.duplicate("a", 256),
        benefit_type: random_enum_value(:employee_benefit_type),
        is_for_dependent: Enum.random([true, false]),
        benefit_amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert changeset = Benefit.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        description: ["should be at most 255 character(s)"]
      }
    end
  end

  describe "create_from_model_changeset" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100),
        benefit_model_id: UUID.generate()
      }

      assert changeset = Benefit.create_from_model_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        description: attrs[:description],
        is_for_dependent: attrs[:is_for_dependent],
        start_date: attrs[:start_date],
        benefit_model_id: attrs[:benefit_model_id],
        is_from_model: true
      }
    end

    test "missing required attrs" do
      assert changeset = Benefit.create_from_model_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
        org_id: ["can't be blank"],
        registration_id: ["can't be blank"],
        is_for_dependent: ["can't be blank"],
        start_date: ["can't be blank"],
        benefit_model_id: ["can't be blank"]
      }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        is_for_dependent: :invalid,
        start_date: :invalid,
        benefit_model_id: :invalid
      }

      assert changeset = Benefit.create_from_model_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        org_id: ["is invalid"],
        registration_id: ["is invalid"],
        is_for_dependent: ["is invalid"],
        start_date: ["is invalid"],
        benefit_model_id: ["is invalid"]
      }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100),
        is_from_model: true,
        end_date: Faker.Date.backward(1),
        benefit_model_id: UUID.generate()
      }

      assert changeset = Benefit.create_from_model_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        description: attrs[:description],
        is_for_dependent: attrs[:is_for_dependent],
        start_date: attrs[:start_date],
        benefit_model_id: attrs[:benefit_model_id],
        is_from_model: true
      }
    end

    test "benefit_model assoc constraint" do
      registration = insert(:employee_registration)

      attrs = %{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.sentence(),
        is_for_dependent: Enum.random([true, false]),
        start_date: Faker.Date.backward(100),
        benefit_model_id: UUID.generate()
      }

      assert {:error, changeset} =
        attrs
        |> Benefit.create_from_model_changeset()
        |> Repo.insert()

      assert errors_on(changeset) == %{
        benefit_model: ["does not exist"]
      }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2021-01-01]
      }

      assert changeset = Benefit.update_changeset(benefit, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        end_date: attrs[:end_date]
      }
    end

    test "missing required attrs" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      assert changeset = Benefit.update_changeset(benefit, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{end_date: ["can't be blank"]}
    end

    test "invalid attrs" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: :invalid
      }

      assert changeset = Benefit.update_changeset(benefit, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{end_date: ["is invalid"]}
    end

    test "ignores non permitted attrs" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        benefit_type: random_enum_value(:employee_benefit_type),
        benefit_amount: Enum.random(400_00..600_00),
        start_date: ~D[2020-02-01],
        end_date: ~D[2021-01-01]
      }

      assert changeset = Benefit.update_changeset(benefit, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        end_date: attrs[:end_date]
      }
    end

    test "end_date before start_date" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2019-01-01]
      }

      assert changeset = Benefit.update_changeset(benefit, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        end_date: ["must be after start_date"]
      }
    end

    test "end_date equal to start_date" do
      benefit = insert(:employee_benefit, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2020-01-01]
      }

      assert changeset = Benefit.update_changeset(benefit, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        end_date: ["must be after start_date"]
      }
    end
  end
end
