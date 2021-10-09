defmodule Sig.HR.Registrations.Suspensions.SuspensionTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Suspensions.Suspension

  describe "employee_suspensions table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      suspension = %Suspension{
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_suspensions\" violates not-null constraint/,
                   fn -> Repo.insert(suspension) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      suspension = %Suspension{
        org_id: UUID.generate(),
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_suspensions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(suspension) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      suspension = %Suspension{
        org_id: org.id,
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_suspensions\" violates not-null constraint/,
                   fn -> Repo.insert(suspension) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      suspension = %Suspension{
        org_id: org.id,
        registration_id: UUID.generate(),
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_suspensions_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(suspension) end
    end

    test "employee_suspensions_start_date_before_or_equal_end_date constraint" do
      registration = insert(:employee_registration)

      suspension = %Suspension{
        org_id: registration.org_id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2021-01-02],
        end_date: ~D[2021-01-01]
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_suspensions_start_date_before_or_equal_end_date \(check_constraint\)/,
                   fn -> Repo.insert(suspension) end
    end

    test "start date cannot be before existing record end date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      # allow when there is no overlapping
      insert(:employee_suspension,
        org: org,
        registration: registration,
        start_date: ~D[2019-12-29],
        end_date: ~D[2019-12-31]
      )

      # allow overlapping for different registration
      insert(:employee_suspension,
        org: org,
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-04]
      )

      suspension = %Suspension{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-04]
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) start_date before or equal to an existing record end_date/,
                   fn -> Repo.insert(suspension) end
    end

    test "end date cannot be after existing record start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      # Allow overlapping for different registration
      insert(:employee_suspension,
        org: org,
        start_date: ~D[2019-12-31],
        end_date: ~D[2020-01-02]
      )

      suspension = %Suspension{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2019-12-31],
        end_date: ~D[2020-01-02]
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) end_date after or equal to an existing record start_date/,
                   fn -> Repo.insert(suspension) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert changeset = Suspension.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               description: attrs[:description],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             }
    end

    test "missing required attrs" do
      assert changeset = Suspension.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               description: ["can't be blank"],
               start_date: ["can't be blank"],
               end_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        description: :invalid,
        start_date: :invalid,
        end_date: :invalid
      }

      assert changeset = Suspension.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               description: ["is invalid"],
               start_date: ["is invalid"],
               end_date: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: String.duplicate("a", 256),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert changeset = Suspension.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end

    test "end date before start date" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.backward(1)
      }

      assert changeset = Suspension.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be equal to or after start_date"]
             }
    end

    test "end date equal to start date" do
      date = Date.utc_today()

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.paragraph(1),
        start_date: date,
        end_date: date
      }

      assert changeset = Suspension.create_changeset(attrs)

      assert changeset.valid?
    end

    test "start_date before the end_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-04]
      }

      assert {:error, changeset} =
               attrs
               |> Suspension.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "start_date equal to the end_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2020-01-03],
        end_date: ~D[2020-01-05]
      }

      assert {:error, changeset} =
               attrs
               |> Suspension.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "end_date after the start_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2019-12-31],
        end_date: ~D[2020-01-02]
      }

      assert {:error, changeset} =
               attrs
               |> Suspension.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "end_date equal to the start_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2019-12-30],
        end_date: ~D[2020-01-01]
      }

      assert {:error, changeset} =
               attrs
               |> Suspension.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "when period doesn't overlap with existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        description: Faker.Lorem.paragraph(1),
        start_date: ~D[2020-01-04],
        end_date: ~D[2020-01-06]
      }

      assert {:ok, _suspension} =
               attrs
               |> Suspension.create_changeset()
               |> Repo.insert()
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      suspension =
        insert(:employee_suspension,
          description: "Pouring the beans before the rice",
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        description: "Putting the beans before the rice",
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-03]
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               start_date: attrs[:start_date],
               end_date: attrs[:end_date]
             }
    end

    test "invalid attrs types" do
      suspension = insert(:employee_suspension)

      attrs = %{
        description: :invalid,
        start_date: :invalid,
        end_date: :invalid
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["is invalid"],
               start_date: ["is invalid"],
               end_date: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      suspension =
        insert(:employee_suspension,
          description: "Pouring the beans before the rice",
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        description: Faker.Lorem.paragraph(1),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               end_date: attrs[:end_date],
               start_date: attrs[:start_date]
             }
    end

    test "string fields length greater than 255 chars" do
      suspension = insert(:employee_suspension)

      attrs = %{
        description: String.duplicate("a", 256),
        start_date: Date.utc_today(),
        end_date: Faker.Date.forward(3)
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end

    test "end date before start date" do
      suspension =
        insert(:employee_suspension,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-01]
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               end_date: ["must be equal to or after start_date"]
             }
    end

    test "end date equal to start date" do
      suspension =
        insert(:employee_suspension,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-02]
        )

      attrs = %{
        start_date: ~D[2020-01-01],
        end_date: ~D[2020-01-01]
      }

      assert changeset = Suspension.update_changeset(suspension, attrs)

      assert changeset.valid?
    end

    test "start_date before the end_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-02-01],
          end_date: ~D[2020-02-03]
        )

      attrs = %{
        start_date: ~D[2020-01-02],
        end_date: ~D[2020-01-04]
      }

      assert {:error, changeset} =
               suspension
               |> Suspension.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "start_date equal to the end_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-02-01],
          end_date: ~D[2020-02-03]
        )

      attrs = %{
        start_date: ~D[2020-01-03],
        end_date: ~D[2020-01-05]
      }

      assert {:error, changeset} =
               suspension
               |> Suspension.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               start_date: ["cannot be before or equal to an existing record end_date"]
             }
    end

    test "end_date after the start_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-02-01],
          end_date: ~D[2020-02-03]
        )

      attrs = %{
        start_date: ~D[2019-12-30],
        end_date: ~D[2020-01-02]
      }

      assert {:error, changeset} =
               suspension
               |> Suspension.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "end_date equal to the start_date of existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-02-01],
          end_date: ~D[2020-02-03]
        )

      attrs = %{
        start_date: ~D[2019-12-31],
        end_date: ~D[2020-01-01]
      }

      assert {:error, changeset} =
               suspension
               |> Suspension.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               end_date: ["cannot be after or equal to an existing record start_date"]
             }
    end

    test "when period doesn't overlap with existing suspension" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _existing_suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-01-01],
          end_date: ~D[2020-01-03]
        )

      suspension =
        insert(:employee_suspension,
          org: org,
          registration: registration,
          start_date: ~D[2020-02-01],
          end_date: ~D[2020-02-03]
        )

      attrs = %{
        start_date: ~D[2020-01-04],
        end_date: ~D[2020-01-06]
      }

      assert {:ok, _suspension} =
               suspension
               |> Suspension.update_changeset(attrs)
               |> Repo.update()
    end
  end
end
