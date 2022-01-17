defmodule Sig.HR.Registrations.CompanyAssignments.CompanyAssignmentTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment

  describe "employee_company_assignments table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      company = insert(:company, org: org)

      assignment = %CompanyAssignment{
        registration_id: registration.id,
        company_id: company.entity_id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)
      company = insert(:company, org: org)

      assignment = %CompanyAssignment{
        org_id: org.id,
        company_id: company.entity_id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "company_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      assignment = %CompanyAssignment{
        org_id: org.id,
        registration_id: registration.id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"company_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "[:start_date, :company_id, :registration_id, :org_id] unique_constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      company = insert(:company, org: org)

      _existing_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          company: company,
          start_date: start_date
        )

      # Allow different date
      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        company: company,
        start_date: ~D[2022-02-01]
      )

      assignment = %CompanyAssignment{
        org_id: org.id,
        registration_id: registration.id,
        company_id: company.entity_id,
        start_date: start_date
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_company_assignments_company_start_date \(unique_constraint\)/,
                   fn -> Repo.insert(assignment) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        company_id: UUID.generate(),
        start_date: ~D[2022-01-01]
      }

      assert changeset = CompanyAssignment.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               company_id: attrs[:company_id],
               start_date: attrs[:start_date]
             }
    end

    test "missing required attrs" do
      assert changeset = CompanyAssignment.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               company_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        company_id: :invalid,
        start_date: :invalid
      }

      assert changeset = CompanyAssignment.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               company_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end

    test "company assoc constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        company_id: UUID.generate(),
        start_date: start_date
      }

      assert {:error, changeset} =
               attrs
               |> CompanyAssignment.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               company: ["does not exist"]
             }
    end

    test "[:start_date, :company_id, :registration_id, :org_id] unique constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      company = insert(:company, org: org)

      _existing_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          company: company,
          start_date: start_date
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        company_id: company.entity_id,
        start_date: start_date
      }

      assert {:error, changeset} =
               attrs
               |> CompanyAssignment.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }
    end
  end
end
