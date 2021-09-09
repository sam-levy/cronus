defmodule Sig.Organizations.Entities.CompanyTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Company

  describe "new_real_changeset/2" do
    test "valid params" do
      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_real_changeset(%Company{}, params)

      assert changeset.valid?

      assert changeset.changes == %{
               trade_name: params[:trade_name],
               registration_name: params[:registration_name],
               cnpj: params[:cnpj],
               organization_id: params[:organization_id]
             }
    end

    test "missing required params" do
      assert changeset = Company.new_real_changeset(%Company{}, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["can't be blank"],
               registration_name: ["can't be blank"],
               cnpj: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid params types" do
      params = %{
        trade_name: :invalid,
        registration_name: :invalid,
        cnpj: :invalid,
        organization_id: :invalid
      }

      assert changeset = Company.new_real_changeset(%Company{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["is invalid"],
               registration_name: ["is invalid"],
               cnpj: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      {:ok, formated_cnpj} =
        BrazilianDocuments.generate_cnpj() |> BrazilianDocuments.format_cnpj()

      params = %{
        trade_name: String.duplicate("a", 256),
        registration_name: String.duplicate("a", 256),
        cnpj: formated_cnpj,
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_real_changeset(%Company{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["should be at most 255 character(s)"],
               registration_name: ["should be at most 255 character(s)"],
               cnpj: ["should be at most 14 character(s)"]
             }
    end

    test "invalid cnpj" do
      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: "47689156000196",
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_real_changeset(%Company{}, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["has invalid cnpj"]}
    end

    test "[cnpj, organization_id] unique constraint" do
      cnpj = BrazilianDocuments.generate_cnpj()

      organization = insert(:organization)
      insert(:company, cnpj: cnpj, organization: organization)

      entity = insert(:entity)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: cnpj,
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_real_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cnpj: ["has already been taken"]}
    end

    test "[registration_name, organization_id] unique constraint" do
      registration_name = Faker.Company.name()

      organization = insert(:organization)
      insert(:company, registration_name: registration_name, organization: organization)

      entity = insert(:entity)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: registration_name,
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_real_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{registration_name: ["has already been taken"]}
    end

    test "[trade_name, organization_id] unique constraint" do
      trade_name = Faker.Company.name()

      organization = insert(:organization)
      insert(:company, trade_name: trade_name, organization: organization)

      entity = insert(:entity)

      params = %{
        trade_name: trade_name,
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_real_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_real_changeset(params)
               |> put_change(:entity_id, UUID.generate())
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_real_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end

    test "rise Ecto.ConstraintError when registration_name is NULL" do
      entity = insert(:entity)
      organization = insert(:organization)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     %Company{}
                     |> Company.new_real_changeset(params)
                     |> put_change(:entity_id, entity.id)
                     |> drop_change(:registration_name)
                     |> Repo.insert()
                   end
    end

    test "rise Ecto.ConstraintError when cnpj is NULL" do
      entity = insert(:entity)
      organization = insert(:organization)

      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: organization.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/companies_registration_name_and_cnpj_required_if_not_virtual/,
                   fn ->
                     %Company{}
                     |> Company.new_real_changeset(params)
                     |> put_change(:entity_id, entity.id)
                     |> drop_change(:cnpj)
                     |> Repo.insert()
                   end
    end
  end

  describe "new_virtual_changeset/2" do
    test "valid params" do
      params = %{
        trade_name: Faker.Company.name(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_virtual_changeset(%Company{}, params)

      assert changeset.valid?

      assert changeset.changes == %{
               trade_name: params[:trade_name],
               organization_id: params[:organization_id],
               is_virtual: true
             }
    end

    test "ignore real company params" do
      params = %{
        trade_name: Faker.Company.name(),
        registration_name: Faker.Company.name(),
        cnpj: BrazilianDocuments.generate_cnpj(),
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_virtual_changeset(%Company{}, params)

      assert changeset.valid?

      assert changeset.changes == %{
               trade_name: params[:trade_name],
               organization_id: params[:organization_id],
               is_virtual: true
             }
    end

    test "missing required params" do
      assert changeset = Company.new_virtual_changeset(%Company{}, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid params types" do
      params = %{
        trade_name: :invalid,
        organization_id: :invalid
      }

      assert changeset = Company.new_virtual_changeset(%Company{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               trade_name: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      params = %{
        trade_name: String.duplicate("a", 256),
        organization_id: UUID.generate()
      }

      assert changeset = Company.new_virtual_changeset(%Company{}, params)

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

      params = %{
        trade_name: trade_name,
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_virtual_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{trade_name: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      params = %{
        trade_name: Faker.Company.name(),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_virtual_changeset(params)
               |> put_change(:entity_id, UUID.generate())
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      params = %{
        trade_name: Faker.Company.name(),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               %Company{}
               |> Company.new_virtual_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end
  end
end
