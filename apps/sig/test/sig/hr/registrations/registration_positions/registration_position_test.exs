defmodule Sig.HR.Registrations.RegistrationPositions.RegistrationPositionTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.RegistrationPositions.RegistrationPosition

  describe "registration_org_positions table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      registration_position = %RegistrationPosition{
        registration_id: registration.id,
        position_id: position.id,
        start_date: registration.admission_date
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"registration_org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(registration_position) end
    end

    test "org_id foreign_key_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      registration_position = %RegistrationPosition{
        org_id: UUID.generate(),
        registration_id: registration.id,
        position_id: position.id,
        start_date: registration.admission_date
      }

      assert_raise Ecto.ConstraintError,
                   ~r/registration_org_positions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(registration_position) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)
      position = insert(:org_position, org: org)

      registration_position = %RegistrationPosition{
        org: org,
        position_id: position.id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"registration_org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(registration_position) end
    end

    test "position_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      registration_position = %RegistrationPosition{
        org: org,
        registration_id: registration.id,
        start_date: registration.admission_date
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"position_id\" of relation \"registration_org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(registration_position) end
    end

    test "[:start_date, :registration_id, :org_id] unique_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      _existing_registration_position =
        insert(:registration_position,
          org: org,
          registration: registration,
          position: position,
          start_date: registration.admission_date
        )

      # Allow same start_date for different registration
      insert(:employee_salary,
        org: org,
        position: position,
        start_date: registration.admission_date
      )

      # Allow same registration and position for different start_date
      insert(:employee_salary,
        org: org,
        registration: registration,
        position: position,
        start_date: Date.add(registration.admission_date, 10)
      )

      new_position = insert(:org_position, org: org)

      registration_position = %RegistrationPosition{
        org: org,
        registration_id: registration.id,
        position_id: new_position.id,
        start_date: registration.admission_date
      }

      assert_raise Ecto.ConstraintError,
                   ~r/registration_org_positions_start_date \(unique_constraint\)/,
                   fn -> Repo.insert(registration_position) end
    end
  end

  describe "registration_org_positions delete stored procedure" do
    test "raises on delete if registration has only one registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      registration_position =
        insert(:employee_salary,
          org: org,
          registration: registration,
          position: position,
          start_date: registration.admission_date
        )

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) one record with `start_date` equal to `employee_registrations.admission_date` must exist/,
                   fn -> Repo.delete(registration_position) end
    end

    test "when the deleted registration position is the original one" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      registration_position =
        insert(:employee_salary,
          org: org,
          registration: registration,
          position: position,
          start_date: registration.admission_date
        )

      insert(:employee_salary,
        org: org,
        registration: registration,
        position: position,
        start_date: Date.add(registration.admission_date, 10)
      )

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) one record with `start_date` equal to `employee_registrations.admission_date` must exist/,
                   fn -> Repo.delete(registration_position) end
    end

    test "successfully deletes if registration more than one registration position" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      insert(:employee_salary,
        org: org,
        registration: registration,
        position: position,
        start_date: registration.admission_date
      )

      registration_position =
        insert(:employee_salary,
          org: org,
          registration: registration,
          position: position,
          start_date: Date.add(registration.admission_date, 10)
        )

      assert {:ok, _} = Repo.delete(registration_position)
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        position_id: UUID.generate(),
        start_date: Faker.Date.backward(100)
      }

      assert changeset = RegistrationPosition.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               position_id: attrs[:position_id],
               start_date: attrs[:start_date]
             }
    end

    test "missing required attrs" do
      assert changeset = RegistrationPosition.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               position_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        position_id: :invalid,
        start_date: :invalid
      }

      assert changeset = RegistrationPosition.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               position_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end

    test "position assoc constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        position_id: UUID.generate(),
        start_date: Faker.Date.backward(100)
      }

      assert {:error, changeset} =
               attrs
               |> RegistrationPosition.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               position: ["does not exist"]
             }
    end

    test "[:start_date, :registration_id, :org_id] unique_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      _existing_registration_position =
        insert(:registration_position,
          org: org,
          registration: registration,
          position: position,
          start_date: registration.admission_date
        )

      new_position = insert(:org_position, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        position_id: new_position.id,
        start_date: registration.admission_date
      }

      assert {:error, changeset} =
               attrs
               |> RegistrationPosition.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      registration_position = insert(:registration_position)

      attrs = %{
        position_id: UUID.generate(),
        start_date: ~D[2021-02-01]
      }

      assert changeset = RegistrationPosition.update_changeset(registration_position, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               position_id: attrs[:position_id],
               start_date: attrs[:start_date]
             }
    end

    test "invalid attrs" do
      registration_position = insert(:registration_position)

      attrs = %{
        position_id: :invalid,
        start_date: :invalid
      }

      assert changeset = RegistrationPosition.update_changeset(registration_position, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               position_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      registration_position = insert(:registration_position)

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        position_id: UUID.generate(),
        start_date: Faker.Date.backward(100)
      }

      assert changeset = RegistrationPosition.update_changeset(registration_position, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               position_id: attrs[:position_id],
               start_date: attrs[:start_date]
             }
    end

    test "position assoc constraint" do
      registration_position = insert(:registration_position)

      attrs = %{
        position_id: UUID.generate(),
        start_date: Faker.Date.backward(100)
      }

      assert {:error, changeset} =
               registration_position
               |> RegistrationPosition.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               position: ["does not exist"]
             }
    end

    test "[:start_date, :registration_id, :org_id] unique_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      position = insert(:org_position, org: org)

      _existing_registration_position =
        insert(:registration_position,
          org: org,
          registration: registration,
          position: position,
          start_date: registration.admission_date
        )

      registration_position =
        insert(:registration_position,
          org: org,
          registration: registration,
          position: position,
          start_date: Date.add(registration.admission_date, 10)
        )

      new_position = insert(:org_position, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        position_id: new_position.id,
        start_date: registration.admission_date
      }

      assert {:error, changeset} =
               registration_position
               |> RegistrationPosition.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }
    end
  end
end
