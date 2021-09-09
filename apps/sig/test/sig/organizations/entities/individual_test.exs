defmodule Sig.Organizations.Entities.IndividualTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Individual
  alias Sig.Organizations.Entities.Individual.Gender

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               entity_id: attrs[:entity_id],
               name: attrs[:name],
               cpf: attrs[:cpf],
               gender: String.to_atom(attrs[:gender]),
               organization_id: attrs[:organization_id]
             }
    end

    test "missing required attrs" do
      assert changeset = Individual.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["can't be blank"],
               name: ["can't be blank"],
               cpf: ["can't be blank"],
               gender: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        entity_id: :invalid,
        name: :invalid,
        cpf: :invalid,
        gender: 1,
        organization_id: :invalid
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity_id: ["is invalid"],
               name: ["is invalid"],
               cpf: ["is invalid"],
               gender: ["is invalid"],
               organization_id: ["is invalid"]
             }
    end

    test "string fields length greater than accepted" do
      {:ok, formated_cpf} = BrazilianDocuments.generate_cpf() |> BrazilianDocuments.format_cpf()

      attrs = %{
        entity_id: UUID.generate(),
        name: String.duplicate("a", 256),
        cpf: formated_cpf,
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"],
               cpf: ["should be at most 11 character(s)"]
             }
    end

    test "invalid cpf" do
      attrs = %{
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: "00887718061",
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has invalid cpf"]}
    end

    test "[cpf, organization_id] unique constraint" do
      cpf = BrazilianDocuments.generate_cpf()

      organization = insert(:organization)
      insert(:individual, cpf: cpf, organization: organization)

      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: cpf,
        gender: random_enum_value(Gender),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Individual.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has already been taken"]}
    end

    test "entity assoc constraint" do
      organization = insert(:organization)

      attrs = %{
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: organization.id
      }

      assert {:error, changeset} =
               attrs
               |> Individual.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
    end

    test "organization assoc constraint" do
      entity = insert(:entity)

      attrs = %{
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> Individual.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      individual = insert(:individual, gender: :male)

      attrs = %{
        name: "New Name",
        gender: :other
      }

      assert changeset = Individual.update_changeset(individual, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               name: attrs[:name],
               gender: attrs[:gender]
             }
    end

    test "ignores non permitted attrs" do
      individual = insert(:individual, gender: :female)

      attrs = %{
        name: "New Name",
        cpf: BrazilianDocuments.generate_cpf(),
        gender: :other,
        organization_id: UUID.generate()
      }

      assert changeset = Individual.update_changeset(individual, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               name: attrs[:name],
               gender: attrs[:gender]
             }
    end

    test "invalid attrs types" do
      individual = insert(:individual, gender: :female)

      attrs = %{
        name: :invalid,
        gender: 1
      }

      assert changeset = Individual.update_changeset(individual, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["is invalid"],
               gender: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      individual = insert(:individual, gender: :male)

      attrs = %{
        name: String.duplicate("a", 256),
        gender: :other
      }

      assert changeset = Individual.update_changeset(individual, attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["should be at most 255 character(s)"]}
    end
  end
end
