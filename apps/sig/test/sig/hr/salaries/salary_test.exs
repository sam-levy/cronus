defmodule Sig.HR.Registrations.Salaries.SalaryTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Salaries.Salary

  describe "employee_salaries table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      salary = %Salary{
        registration_id: registration.id,
        start_date: Faker.Date.backward(100),
        amount: Enum.random(1_200_00..4_000_00)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_salaries\" violates not-null constraint/,
                   fn -> Repo.insert(salary) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      salary = %Salary{
        org_id: UUID.generate(),
        registration_id: registration.id,
        start_date: Faker.Date.backward(100),
        amount: Enum.random(1_200_00..4_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_salaries_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(salary) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      salary = %Salary{
        org_id: org.id,
        start_date: Faker.Date.backward(100),
        amount: Enum.random(1_200_00..4_000_00)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_salaries\" violates not-null constraint/,
                   fn -> Repo.insert(salary) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      salary = %Salary{
        org_id: org.id,
        registration_id: UUID.generate(),
        start_date: Faker.Date.backward(100),
        amount: Enum.random(1_200_00..4_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_salaries_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(salary) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        start_date: Faker.Date.backward(100),
        amount: Enum.random(1_200_00..4_000_00)
      }

      assert changeset = Salary.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               start_date: attrs[:start_date],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "missing required attrs" do
      assert changeset = Salary.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        start_date: :invalid,
        amount: :invalid
      }

      assert changeset = Salary.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["is invalid"],
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end
  end
end
