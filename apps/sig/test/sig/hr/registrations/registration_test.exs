defmodule Sig.HR.Registrations.RegistrationTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Registrations.Registration

  describe "employee_registrations table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:resignation_type),
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
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: UUID.generate(),
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:resignation_type),
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

      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:resignation_type),
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

      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2010-01-02], ~D[2020-01-01]),
        resignation_type: random_enum_value(:resignation_type),
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
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
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

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registrations_resignation_date_is_null_unique \(unique_constraint\)/,
                   fn -> Repo.insert(registration) end
    end

    test "resignation_type_required_if_resignation_date_not_null constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
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
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      registration = %Registration{
        org_id: org.id,
        admission_date: ~D[2010-01-02],
        resignation_date: ~D[2000-01-01],
        resignation_type: random_enum_value(:resignation_type),
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

  describe "create_changeset/1" do
    test "valid attrs" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)
      work_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: work_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert changeset = Registration.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               admission_date: attrs[:admission_date],
               sector_id: attrs[:sector_id],
               position_id: attrs[:position_id],
               individual_id: attrs[:individual_id],
               registered_at_id: attrs[:registered_at_id],
               work_at_id: attrs[:work_at_id],
               salary_amount: %Money{amount: attrs[:salary_amount], currency: :BRL}
             }
    end

    test "missing required attrs" do
      assert changeset = Registration.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               admission_date: ["can't be blank"],
               individual_id: ["can't be blank"],
               org_id: ["can't be blank"],
               position_id: ["can't be blank"],
               registered_at_id: ["can't be blank"],
               sector_id: ["can't be blank"],
               salary_amount: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        admission_date: :invalid,
        sector_id: :invalid,
        position_id: :invalid,
        individual_id: :invalid,
        registered_at_id: :invalid,
        salary_amount: :invalid
      }

      assert changeset = Registration.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               admission_date: ["is invalid"],
               sector_id: ["is invalid"],
               position_id: ["is invalid"],
               individual_id: ["is invalid"],
               registered_at_id: ["is invalid"],
               salary_amount: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_type: random_enum_value(:resignation_type),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert changeset = Registration.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               admission_date: attrs[:admission_date],
               sector_id: attrs[:sector_id],
               position_id: attrs[:position_id],
               individual_id: attrs[:individual_id],
               registered_at_id: attrs[:registered_at_id],
               work_at_id: attrs[:work_at_id],
               salary_amount: %Money{amount: attrs[:salary_amount], currency: :BRL}
             }
    end

    test "assign registered_at_id to work_at_id if not in attrs" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert changeset = Registration.create_changeset(attrs)

      assert changeset.valid?
      assert changeset.changes.work_at_id == registered_at.entity_id
    end

    test "[:registered_at_id, :individual_id, :org_id] conditional unique constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      _existing_open_registration =
        insert(:employee_registration,
          org: org,
          individual: individual,
          registered_at: registered_at,
          resignation_date: nil,
          resignation_type: nil
        )

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{registered_at_id: ["has already been taken"]}
    end

    test "sector assoc_constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: UUID.generate(),
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{sector: ["does not exist"]}
    end

    test "sector from other org" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      other_org_sector = insert(:org_sector)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: other_org_sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{sector: ["does not exist"]}
    end

    test "position assoc_constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      registered_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: UUID.generate(),
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{position: ["does not exist"]}
    end

    test "position from other org" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      registered_at = insert(:company, org: org)

      other_org_position = insert(:org_position)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: other_org_position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: registered_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{position: ["does not exist"]}
    end

    test "registered_at assoc_constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      work_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: UUID.generate(),
        work_at_id: work_at.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{registered_at: ["does not exist"]}
    end

    test "registered_at company from other org" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      company = insert(:company, org: org)

      other_org_company = insert(:company)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: other_org_company.entity_id,
        work_at_id: company.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{registered_at: ["does not exist"]}
    end

    test "work_at assoc_constraint" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      registered_at = insert(:company, org: org)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: registered_at.entity_id,
        work_at_id: UUID.generate(),
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{work_at: ["does not exist"]}
    end

    test "work_at company from other org" do
      org = insert(:org)

      individual = insert(:individual, org: org)
      sector = insert(:org_sector, org: org)
      position = insert(:org_position, org: org)
      company = insert(:company, org: org)

      other_org_company = insert(:company)

      attrs = %{
        org_id: org.id,
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        sector_id: sector.id,
        position_id: position.id,
        individual_id: individual.entity_id,
        registered_at_id: company.entity_id,
        work_at_id: other_org_company.entity_id,
        salary_amount: Enum.random(1_200_00..4_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> Registration.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{work_at: ["does not exist"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      registration = insert(:employee_registration)

      attrs = %{
        sector_id: UUID.generate(),
        position_id: UUID.generate(),
        work_at_id: UUID.generate()
      }

      assert changeset = Registration.update_changeset(registration, attrs)

      assert changeset.valid?
      assert changeset.changes == attrs
    end

    test "invalid attrs types" do
      registration = insert(:employee_registration)

      attrs = %{
        sector_id: :invalid,
        position_id: :invalid,
        work_at_id: :invalid
      }

      assert changeset = Registration.update_changeset(registration, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               position_id: ["is invalid"],
               sector_id: ["is invalid"],
               work_at_id: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      registration = insert(:employee_registration)

      attrs = %{
        org_id: UUID.generate(),
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_type: random_enum_value(:resignation_type),
        sector_id: UUID.generate(),
        position_id: UUID.generate(),
        individual_id: UUID.generate(),
        registered_at_id: UUID.generate(),
        work_at_id: UUID.generate()
      }

      assert changeset = Registration.update_changeset(registration, attrs)

      assert changeset.valid?
      assert changeset.changes == Map.take(attrs, [:position_id, :sector_id, :work_at_id])
    end

    test "sector assoc_constraint" do
      registration = insert(:employee_registration)

      position = insert(:org_position, org: registration.org)
      work_at = insert(:company, org: registration.org)

      attrs = %{
        sector_id: UUID.generate(),
        position_id: position.id,
        work_at_id: work_at.entity_id
      }

      assert {:error, changeset} =
               registration
               |> Registration.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{sector: ["does not exist"]}
    end

    test "position assoc_constraint" do
      registration = insert(:employee_registration)

      sector = insert(:org_sector, org: registration.org)
      work_at = insert(:company, org: registration.org)

      attrs = %{
        sector_id: sector.id,
        position_id: UUID.generate(),
        work_at_id: work_at.entity_id
      }

      assert {:error, changeset} =
               registration
               |> Registration.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{position: ["does not exist"]}
    end

    test "work_at assoc_constraint" do
      registration = insert(:employee_registration)

      sector = insert(:org_sector, org: registration.org)
      position = insert(:org_position, org: registration.org)

      attrs = %{
        sector_id: sector.id,
        position_id: position.id,
        work_at_id: UUID.generate()
      }

      assert {:error, changeset} =
               registration
               |> Registration.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{work_at: ["does not exist"]}
    end
  end

  describe "resignation_changeset/2" do
    test "valid attrs" do
      registration = insert(:employee_registration, admission_date: ~D[2000-01-01])

      attrs = %{
        resignation_date: ~D[2010-01-01],
        resignation_type: random_enum_value(:resignation_type)
      }

      assert changeset = Registration.resignation_changeset(registration, attrs)

      assert changeset.valid?
      assert changeset.changes == attrs
    end

    test "missing required attrs" do
      registration = insert(:employee_registration)

      assert changeset = Registration.resignation_changeset(registration, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               resignation_date: ["can't be blank"],
               resignation_type: ["can't be blank"]
             }
    end

    test "invalid attrs" do
      registration = insert(:employee_registration)

      attrs = %{
        resignation_date: :invalid,
        resignation_type: :invalid
      }

      assert changeset = Registration.resignation_changeset(registration, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               resignation_date: ["is invalid"],
               resignation_type: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      registration = insert(:employee_registration, admission_date: ~D[2000-01-01])

      attrs = %{
        org_id: UUID.generate(),
        admission_date: Faker.Date.between(~D[2000-01-01], ~D[2010-01-01]),
        resignation_date: ~D[2010-01-01],
        resignation_type: random_enum_value(:resignation_type),
        sector_id: UUID.generate(),
        position_id: UUID.generate(),
        individual_id: UUID.generate(),
        registered_at_id: UUID.generate(),
        work_at_id: UUID.generate()
      }

      assert changeset = Registration.resignation_changeset(registration, attrs)

      assert changeset.valid?
      assert changeset.changes == Map.take(attrs, [:resignation_date, :resignation_type])
    end

    test "admission_date before resignation_date" do
      registration = insert(:employee_registration, admission_date: ~D[2021-01-02])

      attrs = %{
        resignation_date: ~D[2021-01-01],
        resignation_type: random_enum_value(:resignation_type)
      }

      assert changeset = Registration.resignation_changeset(registration, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               admission_date: ["must be before resignation_date"]
             }
    end
  end
end
