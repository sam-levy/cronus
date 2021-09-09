defmodule Sig.Organizations.Entities.IndividualTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Individual
  alias Sig.Organizations.Entities.Individual.Gender

  describe "new_changeset/2" do
    test "valid params" do
      params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      assert changeset.valid?

      assert changeset.changes == %{
               name: params[:name],
               cpf: params[:cpf],
               gender: String.to_atom(params[:gender]),
               organization_id: params[:organization_id]
             }
    end

    test "missing required params" do
      assert changeset = Individual.new_changeset(%Individual{}, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               cpf: ["can't be blank"],
               gender: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid params types" do
      params = %{
        name: :invalid,
        cpf: :invalid,
        gender: 1,
        organization_id: :invalid
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["is invalid"],
               cpf: ["is invalid"],
               gender: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      {:ok, formated_cpf} = BrazilianDocuments.generate_cpf() |> BrazilianDocuments.format_cpf()

      params = %{
        name: String.duplicate("a", 256),
        cpf: formated_cpf,
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"],
               cpf: ["should be at most 11 character(s)"]
             }
    end

    test "invalid cpf" do
      params = %{
        name: Faker.Person.name(),
        cpf: "00887718061",
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has invalid cpf"]}
    end

    test "[cpf, organization_id] unique constraint" do
      cpf = BrazilianDocuments.generate_cpf()

      organization = insert(:organization)
      insert(:individual, cpf: cpf, organization: organization)

      entity = insert(:entity)

      params = %{
        name: Faker.Person.name(),
        cpf: cpf,
        gender: random_enum_value(Gender),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Individual{}
               |> Individual.new_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               %Individual{}
               |> Individual.new_changeset(params)
               |> put_change(:entity_id, UUID.generate())
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               %Individual{}
               |> Individual.new_changeset(params)
               |> put_change(:entity_id, entity.id)
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end
  end

  describe "edit_changeset/2" do
    test "valid params" do
      individual = insert(:individual, gender: :male)

      params = %{
        name: "New Name",
        gender: :other
      }

      assert changeset = Individual.edit_changeset(individual, params)

      assert changeset.valid?

      assert changeset.changes == %{
               name: params[:name],
               gender: params[:gender]
             }
    end

    test "ignores non permitted params" do
      individual = insert(:individual, gender: :female)

      params = %{
        name: "New Name",
        cpf: BrazilianDocuments.generate_cpf(),
        gender: :other,
        organization_id: UUID.generate()
      }

      assert changeset = Individual.edit_changeset(individual, params)

      assert changeset.valid?

      assert changeset.changes == %{
               name: params[:name],
               gender: params[:gender]
             }
    end

    test "invalid params types" do
      individual = insert(:individual, gender: :female)

      params = %{
        name: :invalid,
        gender: 1
      }

      assert changeset = Individual.edit_changeset(individual, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["is invalid"],
               gender: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      individual = insert(:individual, gender: :male)

      params = %{
        name: String.duplicate("a", 256),
        gender: :other
      }

      assert changeset = Individual.edit_changeset(individual, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["should be at most 255 character(s)"]}
    end
  end
end
