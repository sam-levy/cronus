defmodule Sig.HR.Registrations.RegistrationTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Registration

  describe "employee_registrations table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:registration_type),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "employee_registrations\" violates not-null constraint/,
                   fn -> Repo.insert(registration) end
    end

    test "org_id foreign_key_constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: UUID.generate(),
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:registration_type),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registrations_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(registration) end
    end

    test "individual_id not_null_violation" do
      org = insert(:org)

      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:registration_type),
        sector_id: sector.id,
        position_id: position.id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "individual_id" of relation "employee_registrations\" violates not-null constraint/,
                   fn -> Repo.insert(registration) end
    end

    test "individual_id foreign_key_constraint" do
      org = insert(:org)

      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:registration_type),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: UUID.generate(),
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registrations_individual_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(registration) end
    end

    test "[:registered_at_id, :individual_id, :org_id] employee_registrations_resignation_date_is_null_unique" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      _existing_open_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: registered_at,
          resignation_date: nil,
          resignation_type: nil
        )

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise  Ecto.ConstraintError,
                   ~r/employee_registrations_resignation_date_is_null_unique \(unique_constraint\)/,
                   fn -> Repo.insert(registration) end
    end

    test "resignation_type_required_if_resignation_date_not_null constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/resignation_type_required_if_resignation_date_not_null \(check_constraint\)/,
                   fn -> Repo.insert(registration) end
    end

    test "employee_registrations_admission_before_resignation constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:sector, org: org)
      position = insert(:position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: ~D[2010-01-02],
        resignation_date: ~D[2000-01-01],
        resignation_type: random_enum_value(:registration_type),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registrations_admission_before_resignation \(check_constraint\)/,
                   fn -> Repo.insert(registration) end
    end
  end
end
