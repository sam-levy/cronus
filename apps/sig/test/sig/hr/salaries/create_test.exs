defmodule Sig.HR.Registrations.Salaries.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Salaries.Salary
  alias Sig.HR.Registrations.Salaries.Create

  describe "call/3" do
    test "creates a salary" do
      registration = insert(:employee_registration)

      attrs = %{
        start_date: ~D[2021-01-01],
        amount: 1_500_00
      }

      assert {:ok, %Salary{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Salary,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               start_date: attrs[:start_date],
               amount: attrs[:amount]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Create.call(registration, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "same start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_salary, org: org, registration: registration, start_date: ~D[2020-01-01])
      insert(:employee_salary, org: org, registration: registration, start_date: ~D[2021-01-01])

      attrs = %{
        start_date: ~D[2021-01-01],
        amount: 1_500_00
      }

      assert Create.call(registration, attrs) ==
               {:error, "a data de início deve ser posterior a data de início do último salário"}
    end

    test "inferior start date" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert(:employee_salary, org: org, registration: registration, start_date: ~D[2021-01-01])

      attrs = %{
        start_date: ~D[2020-02-02],
        amount: 1_500_00
      }

      assert Create.call(registration, attrs) ==
               {:error, "a data de início deve ser posterior a data de início do último salário"}
    end
  end
end
