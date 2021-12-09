defmodule Sig.HR.Registrations.Warnings.WarningTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Warnings.Warning

  describe "employee_warnings table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      warning = %Warning{
        registration_id: registration.id,
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_warnings\" violates not-null constraint/,
                   fn -> Repo.insert(warning) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      warning = %Warning{
        org_id: UUID.generate(),
        registration_id: registration.id,
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_warnings_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(warning) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      warning = %Warning{
        org_id: org.id,
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_warnings\" violates not-null constraint/,
                   fn -> Repo.insert(warning) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      warning = %Warning{
        org_id: org.id,
        registration_id: UUID.generate(),
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_warnings_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(warning) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert changeset = Warning.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               date: attrs[:date],
               description: attrs[:description]
             }
    end

    test "missing required attrs" do
      assert changeset = Warning.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               date: ["can't be blank"],
               description: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        date: :invalid,
        description: :invalid
      }

      assert changeset = Warning.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               date: ["is invalid"],
               description: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        date: Date.utc_today(),
        description: String.duplicate("a", 256)
      }

      assert changeset = Warning.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      warning =
        insert(:employee_warning,
          date: ~D[2020-01-01],
          description: "Pouring the beans before the rice"
        )

      attrs = %{
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert changeset = Warning.update_changeset(warning, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               date: attrs[:date],
               description: attrs[:description]
             }
    end

    test "invalid attrs types" do
      warning = insert(:employee_warning)

      attrs = %{
        date: :invalid,
        description: :invalid
      }

      assert changeset = Warning.update_changeset(warning, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["is invalid"],
               description: ["is invalid"]
             }
    end

    test "nil required attrs" do
      warning = insert(:employee_warning)

      attrs = %{
        date: nil,
        description: nil
      }

      assert changeset = Warning.update_changeset(warning, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               description: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      warning =
        insert(:employee_warning,
          date: ~D[2020-01-01],
          description: "Pouring the beans before the rice"
        )

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        date: Date.utc_today(),
        description: Faker.Lorem.paragraph(1)
      }

      assert changeset = Warning.update_changeset(warning, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               date: attrs[:date],
               description: attrs[:description]
             }
    end

    test "string fields length greater than 255 chars" do
      warning = insert(:employee_warning)

      attrs = %{
        date: Date.utc_today(),
        description: String.duplicate("a", 256)
      }

      assert changeset = Warning.update_changeset(warning, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end
  end
end
