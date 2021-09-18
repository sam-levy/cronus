defmodule Sig.Entities.Companies.CompanyTest do
  use Sig.DataCase

  alias BrazilianDocuments.Types.CNPJ

  alias Sig.Entities.Companies.Company

  describe "companies table constraints" do
    test "entity_id not_null_violation" do
      org = insert(:org)

      company = %Company{
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "entity_id" of relation "companies" violates not-null constraint/,
                   fn -> Repo.insert(company) end
    end

    test "org_id not_null_violation" do
      entity = insert(:entity)

      company = %Company{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "companies" violates not-null constraint/,
                   fn -> Repo.insert(company) end
    end

    test "entity_id foreign_key_constraint" do
      org = insert(:org)

      company = %Company{
        entity_id: UUID.generate(),
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(company) end
    end

    test "org_id foreign_key_constraint" do
      entity = insert(:entity)

      company = %Company{
        entity_id: entity.id,
        org_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(company) end
    end

    test "registration_name not null constraint when is_virtual is false" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      company = %Company{
        is_virtual: false,
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn -> Repo.insert(company) end
    end

    test "cnpj not null constraint when is_virtual is false" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      company = %Company{
        is_virtual: false,
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn -> Repo.insert(company) end
    end

    test "[registration_name, org_id] unique_constraint" do
      registration_name = Faker.Company.name()

      org = insert(:org)
      insert(:company, registration_name: registration_name, org: org)

      entity = insert(:entity, org: org)

      company = %Company{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: registration_name,
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(company) end
    end

    test "[trade_name, org_id] unique_constraint" do
      trade_name = Faker.Company.name()

      org = insert(:org)
      insert(:company, trade_name: trade_name, org: org)

      entity = insert(:entity, org: org)

      company = %Company{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: trade_name,
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_trade_name_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(company) end
    end

    test "[cnpj, org_id] unique_constraint" do
      cnpj = BrazilianDocuments.generate_cnpj()

      org = insert(:org)
      insert(:company, cnpj: cnpj, org: org)

      entity = insert(:entity, org: org)

      company = %Company{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: cnpj
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_cnpj_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(company) end
    end
  end

  describe "create_real_changeset/1" do
    test "valid attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert changeset = Company.create_real_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               org_id: attrs[:org_id],
               trade_name: attrs[:trade_name],
               registration_name: attrs[:registration_name],
               cnpj: %CNPJ{number: attrs[:cnpj]}
             }
    end

    test "missing required attrs" do
      assert changeset = Company.create_real_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["can't be blank"],
               org_id: ["can't be blank"],
               trade_name: ["can't be blank"],
               registration_name: ["can't be blank"],
               cnpj: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        entity_id: :invalid,
        org_id: :invalid,
        trade_name: :invalid,
        registration_name: :invalid,
        cnpj: :invalid
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["is invalid"],
               org_id: ["is invalid"],
               trade_name: ["is invalid"],
               registration_name: ["is invalid"],
               cnpj: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: String.duplicate("a", 256),
        registration_name: String.duplicate("a", 256),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["should be at most 255 character(s)"],
               registration_name: ["should be at most 255 character(s)"]
             }
    end

    test "filters cnpj digit characters" do
      cnpj = BrazilianDocuments.generate_cnpj()
      {:ok, formatted_cnpj} = BrazilianDocuments.format_cnpj(cnpj)

      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: formatted_cnpj
      }

      assert changeset = Company.create_real_changeset(attrs)

      assert changeset.valid?
      assert changeset.changes.cnpj == %CNPJ{number: cnpj}
    end

    test "invalid cnpj" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: "47689156000196"
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["is invalid"]}
    end

    test "[registration_name, org_id] unique constraint" do
      registration_name = Faker.Company.name()

      org = insert(:org)
      insert(:company, registration_name: registration_name, org: org)

      entity = insert(:entity, org: org)

      attrs = %{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: registration_name,
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{registration_name: ["has already been taken"]}
    end

    test "[trade_name, org_id] unique constraint" do
      trade_name = Faker.Company.name()

      org = insert(:org)
      insert(:company, trade_name: trade_name, org: org)

      entity = insert(:entity, org: org)

      attrs = %{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: trade_name,
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end

    test "[cnpj, org_id] unique constraint" do
      cnpj = BrazilianDocuments.generate_cnpj()

      org = insert(:org)
      insert(:company, cnpj: cnpj, org: org)

      entity = insert(:entity, org: org)

      attrs = %{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: cnpj
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["has already been taken"]}
    end
  end

  describe "create_virtual_changeset/2" do
    test "valid attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: Faker.Company.name()
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               org_id: attrs[:org_id],
               trade_name: attrs[:trade_name],
               is_virtual: true
             }
    end

    test "missing required attrs" do
      assert changeset = Company.create_virtual_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["can't be blank"],
               org_id: ["can't be blank"],
               trade_name: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        entity_id: :invalid,
        org_id: :invalid,
        trade_name: :invalid
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["is invalid"],
               org_id: ["is invalid"],
               trade_name: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: String.duplicate("a", 256)
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["should be at most 255 character(s)"]
             }
    end

    test "ignores real company attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        org_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj()
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               org_id: attrs[:org_id],
               trade_name: attrs[:trade_name],
               is_virtual: true
             }
    end

    test "[trade_name, org_id] unique constraint" do
      trade_name = Faker.Company.name()

      org = insert(:org)
      insert(:company, trade_name: trade_name, org: org)

      entity = insert(:entity, org: org)

      attrs = %{
        entity_id: entity.id,
        org_id: org.id,
        trade_name: trade_name
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_virtual_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end
  end
end
