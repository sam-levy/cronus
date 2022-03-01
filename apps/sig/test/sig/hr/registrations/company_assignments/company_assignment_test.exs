defmodule Sig.HR.Registrations.CompanyAssignments.CompanyAssignmentTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment

  describe "employee_company_assignments table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)

      assignment = %CompanyAssignment{
        registration_id: registration.id,
        assigned_company_id: company.entity_id,
        sector_id: sector.id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)

      assignment = %CompanyAssignment{
        org_id: org.id,
        assigned_company_id: company.entity_id,
        sector_id: sector.id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "assigned_company_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      sector = insert(:org_sector, org: org)

      assignment = %CompanyAssignment{
        org_id: org.id,
        registration_id: registration.id,
        sector_id: sector.id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"assigned_company_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "sector_id not_null_violation" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      company = insert(:company, org: org)

      assignment = %CompanyAssignment{
        org_id: org.id,
        registration_id: registration.id,
        assigned_company_id: company.entity_id,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"sector_id\" of relation \"employee_company_assignments\" violates not-null constraint/,
                   fn -> Repo.insert(assignment) end
    end

    test "[:start_date, :assigned_company_id, :registration_id, :org_id] unique_constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)

      _existing_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      # Allow different date
      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        assigned_company: company,
        start_date: ~D[2022-02-01]
      )

      assignment = %CompanyAssignment{
        org_id: org.id,
        registration_id: registration.id,
        assigned_company_id: company.entity_id,
        sector_id: sector.id,
        start_date: start_date
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_company_assignments_company_start_date \(unique_constraint\)/,
                   fn -> Repo.insert(assignment) end
    end
  end

  describe "employee_company_assignments delete stored procedure" do
    test "raises on delete if registration has only one company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      company_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) one record with `start_date` equal to `employee_registrations.admission_date` must exist/,
                   fn -> Repo.delete(company_assignment) end
    end

    test "when the deleted company assignment is the original one" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      company_assignment_1 =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        start_date: Date.utc_today()
      )

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) one record with `start_date` equal to `employee_registrations.admission_date` must exist/,
                   fn -> Repo.delete(company_assignment_1) end
    end

    test "successfully deletes if registration has more than one company assignment" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      _company_assignment_1 =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: registration.admission_date
        )

      company_assignment_2 =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          start_date: Date.utc_today()
        )

      assert {:ok, _} = Repo.delete(company_assignment_2)
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        assigned_company_id: UUID.generate(),
        sector_id: UUID.generate(),
        start_date: ~D[2022-01-01]
      }

      assert changeset = CompanyAssignment.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               assigned_company_id: attrs[:assigned_company_id],
               sector_id: attrs[:sector_id],
               start_date: attrs[:start_date]
             }
    end

    test "missing required attrs" do
      assert changeset = CompanyAssignment.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               assigned_company_id: ["can't be blank"],
               sector_id: ["can't be blank"],
               start_date: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        assigned_company_id: :invalid,
        sector_id: :invalid,
        start_date: :invalid
      }

      assert changeset = CompanyAssignment.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               registration_id: ["is invalid"],
               assigned_company_id: ["is invalid"],
               sector_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end

    test "assigned company assoc constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      sector = insert(:org_sector, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        assigned_company_id: UUID.generate(),
        sector_id: sector.id,
        start_date: start_date
      }

      assert {:error, changeset} =
               attrs
               |> CompanyAssignment.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               assigned_company: ["does not exist"]
             }
    end

    test "sector assoc constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      company = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        assigned_company_id: company.entity_id,
        sector_id: UUID.generate(),
        start_date: start_date
      }

      assert {:error, changeset} =
               attrs
               |> CompanyAssignment.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               sector: ["does not exist"]
             }
    end

    test "[:start_date, :assigned_company_id, :registration_id, :org_id] unique constraint" do
      org = insert(:org)
      start_date = ~D[2022-01-01]
      registration = insert(:employee_registration, org: org, admission_date: start_date)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)

      _existing_assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        assigned_company_id: company.entity_id,
        sector_id: sector.id,
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

  describe "update_changeset/2" do
    test "valid attrs" do
      start_date = ~D[2022-01-01]

      org = insert(:org)
      company = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      attrs = %{
        assigned_company_id: UUID.generate(),
        sector_id: UUID.generate(),
        start_date: ~D[2022-02-01]
      }

      assert changeset = CompanyAssignment.update_changeset(assignment, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               assigned_company_id: attrs[:assigned_company_id],
               sector_id: attrs[:sector_id],
               start_date: attrs[:start_date]
             }
    end

    test "ignores non permitted attrs" do
      start_date = ~D[2022-01-01]

      org = insert(:org)
      company = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        assigned_company_id: UUID.generate(),
        sector_id: UUID.generate(),
        start_date: ~D[2022-02-01]
      }

      assert changeset = CompanyAssignment.update_changeset(assignment, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               assigned_company_id: attrs[:assigned_company_id],
               sector_id: attrs[:sector_id],
               start_date: attrs[:start_date]
             }
    end

    test "invalid attrs types" do
      assignment = insert(:employee_company_assignment)

      attrs = %{
        assigned_company_id: :invalid,
        sector_id: :invalid,
        start_date: :invalid
      }

      assert changeset = CompanyAssignment.update_changeset(assignment, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               assigned_company_id: ["is invalid"],
               sector_id: ["is invalid"],
               start_date: ["is invalid"]
             }
    end

    test "assigned company assoc constraint" do
      start_date = ~D[2022-01-01]

      org = insert(:org)
      company = insert(:company, org: org)
      sector = insert(:org_sector, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      attrs = %{
        assigned_company_id: UUID.generate(),
        sector_id: sector.id,
        start_date: ~D[2022-02-01]
      }

      assert {:error, changeset} =
               assignment
               |> CompanyAssignment.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               assigned_company: ["does not exist"]
             }
    end

    test "sector assoc constraint" do
      start_date = ~D[2022-01-01]

      org = insert(:org)
      company = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: start_date
        )

      attrs = %{
        assigned_company_id: company.entity_id,
        sector_id: UUID.generate(),
        start_date: ~D[2022-02-01]
      }

      assert {:error, changeset} =
               assignment
               |> CompanyAssignment.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               sector: ["does not exist"]
             }
    end

    test "[:start_date, :assigned_company_id, :registration_id, :org_id] unique constraint" do
      start_date = ~D[2022-01-01]

      org = insert(:org)
      company = insert(:company, org: org)

      registration =
        insert(:employee_registration,
          org: org,
          registered_at: company,
          admission_date: start_date
        )

      insert(:employee_company_assignment,
        org: org,
        registration: registration,
        assigned_company: company,
        start_date: start_date
      )

      assignment =
        insert(:employee_company_assignment,
          org: org,
          registration: registration,
          assigned_company: company,
          start_date: ~D[2022-02-01]
        )

      attrs = %{
        start_date: start_date
      }

      assert {:error, changeset} =
               assignment
               |> CompanyAssignment.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               start_date: ["has already been taken"]
             }
    end
  end
end
