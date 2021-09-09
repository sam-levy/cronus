defmodule Sig.Organizations.Entities.CompanyTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Company

  describe "create_real_changeset/1" do
    test "valid attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_real_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               trade_name: attrs[:trade_name],
               registration_name: attrs[:registration_name],
               cnpj: attrs[:cnpj],
               organization_id: attrs[:organization_id]
             }
    end

    test "missing required attrs" do
      assert changeset = Company.create_real_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["can't be blank"],
               trade_name: ["can't be blank"],
               registration_name: ["can't be blank"],
               cnpj: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        entity_id: :invalid,
        trade_name: :invalid,
        registration_name: :invalid,
        cnpj: :invalid,
        organization_id: :invalid
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["is invalid"],
               trade_name: ["is invalid"],
               registration_name: ["is invalid"],
               cnpj: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      {:ok, formated_cnpj} =
        BrazilianDocuments.generate_cnpj() |> BrazilianDocuments.format_cnpj()

      attrs = %{
        entity_id: UUID.generate(),
        trade_name: String.duplicate("a", 256),
        registration_name: String.duplicate("a", 256),
        cnpj: formated_cnpj,
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["should be at most 255 character(s)"],
               registration_name: ["should be at most 255 character(s)"],
               cnpj: ["should be at most 14 character(s)"]
             }
    end

    test "invalid cnpj" do
      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: "47689156000196",
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_real_changeset(attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["has invalid cnpj"]}
    end

    test "[cnpj, organization_id] unique constraint" do
      cnpj = BrazilianDocuments.generate_cnpj()

      organization = insert(:organization)
      insert(:company, cnpj: cnpj, organization: organization)

      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: cnpj,
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["has already been taken"]}
    end

    test "[registration_name, organization_id] unique constraint" do
      registration_name = Faker.Company.name()

      organization = insert(:organization)
      insert(:company, registration_name: registration_name, organization: organization)

      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: registration_name,
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{registration_name: ["has already been taken"]}
    end

    test "[trade_name, organization_id] unique constraint" do
      trade_name = Faker.Company.name()

      organization = insert(:organization)
      insert(:company, trade_name: trade_name, organization: organization)

      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: trade_name,
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_real_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end

    test "rise Ecto.ConstraintError when registration_name is NULL" do
      entity = insert(:entity)
      organization = insert(:organization)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     attrs
                     |> Company.create_real_changeset()
                     |> drop_change(:registration_name)
                     |> Repo.insert()
                   end
    end

    test "rise Ecto.ConstraintError when cnpj is NULL" do
      entity = insert(:entity)
      organization = insert(:organization)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     attrs
                     |> Company.create_real_changeset()
                     |> drop_change(:cnpj)
                     |> Repo.insert()
                   end
    end
  end

  describe "create_virtual_changeset/2" do
    test "valid attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               trade_name: attrs[:trade_name],
               organization_id: attrs[:organization_id],
               is_virtual: true
             }
    end

    test "ignore real company attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               trade_name: attrs[:trade_name],
               organization_id: attrs[:organization_id],
               is_virtual: true
             }
    end

    test "missing required attrs" do
      assert changeset = Company.create_virtual_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["can't be blank"],
               trade_name: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        entity_id: :invalid,
        trade_name: :invalid,
        organization_id: :invalid
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["is invalid"],
               trade_name: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      attrs = %{
        entity_id: UUID.generate(),
        trade_name: String.duplicate("a", 256),
        organization_id: UUID.generate()
      }

      assert changeset = Company.create_virtual_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["should be at most 255 character(s)"]
             }
    end

    test "[trade_name, organization_id] unique constraint" do
      trade_name = Faker.Company.name()

      organization = insert(:organization)
      insert(:company, trade_name: trade_name, organization: organization)

      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: trade_name,
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_virtual_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      attrs = %{
        entity_id: UUID.generate(),
        trade_name: Faker.Company.name(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_virtual_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> Company.create_virtual_changeset()
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end

    test "rise Ecto.ConstraintError when registration_name is NOT NULL" do
      entity = insert(:entity)
      organization = insert(:organization)
      registration_name = Faker.Company.name()

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     attrs
                     |> Company.create_virtual_changeset()
                     |> put_change(:registration_name, registration_name)
                     |> Repo.insert()
                   end
    end

    test "rise Ecto.ConstraintError when cnpj is NOT NULL" do
      entity = insert(:entity)
      organization = insert(:organization)
      cnpj = BrazilianDocuments.generate_cnpj()

      attrs = %{
        entity_id: entity.id,
        trade_name: Faker.Company.name(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     attrs
                     |> Company.create_virtual_changeset()
                     |> put_change(:cnpj, cnpj)
                     |> Repo.insert()
                   end
    end
  end
end
