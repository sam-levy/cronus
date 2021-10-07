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
               start_date: ["must be before or equal to end_date"]
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
               start_date: ["must be before or equal to end_date"]
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
  end
end
