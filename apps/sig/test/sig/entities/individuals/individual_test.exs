defmodule Sig.Entities.Individuals.IndividualTest do
  use Sig.DataCase

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Individuals.Individual

  describe "individuals table constraints" do
    test "[entity_id, org_id] individuals_pkey unique_constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      _existing_individual = insert(:individual, org: org, entity: entity)

      individual = %Individual{
        org_id: org.id,
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/individuals_pkey \(unique_constraint\)/,
                   fn -> Repo.insert(individual) end
    end

    test "entity_id not_null_violation" do
      org = insert(:org)

      individual = %Individual{
        org_id: org.id,
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "entity_id" of relation "individuals" violates not-null constraint/,
                   fn -> Repo.insert(individual) end
    end

    test "org_id not_null_violation" do
      entity = insert(:entity)

      individual = %Individual{
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "individuals" violates not-null constraint/,
                   fn -> Repo.insert(individual) end
    end

    test "entity_id foreign_key_constraint" do
      org = insert(:org)

      individual = %Individual{
        org_id: org.id,
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/individuals_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(individual) end
    end

    test "org_id foreign_key_constraint" do
      entity = insert(:entity)

      individual = %Individual{
        org_id: UUID.generate(),
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/individuals_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(individual) end
    end

    test "[cpf, org_id] unique_constraint" do
      cpf = BrazilianDocuments.generate_cpf()

      org = insert(:org)
      insert(:individual, org: org, cpf: cpf)

      entity = insert(:entity, org: org)

      individual = %Individual{
        org_id: org.id,
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: cpf,
        gender: random_enum_value(:gender)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/individuals_cpf_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(individual) end
    end
  end

  describe "cast_params/1" do
    test "cast params" do
      params = %{
        "cpf" => BrazilianDocuments.generate_cpf(),
        "name" => Faker.Person.name(),
        "gender" => random_enum_value(:gender)
      }

      assert Individual.cast_params(params) == %{
               cpf: %CPF{number: params["cpf"]},
               name: params["name"],
               gender: params["gender"]
             }
    end

    test "filters valid params" do
      params = %{
        "cnpj" => BrazilianDocuments.generate_cnpj(),
        "name" => Faker.Person.name(),
        "gender" => random_enum_value(:gender)
      }

      assert Individual.cast_params(params) == %{
               name: params["name"],
               gender: params["gender"]
             }
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert changeset = Individual.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               entity_id: attrs[:entity_id],
               name: attrs[:name],
               cpf: %CPF{number: attrs[:cpf]},
               gender: attrs[:gender]
             }
    end

    test "missing required attrs" do
      assert changeset = Individual.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               entity_id: ["can't be blank"],
               name: ["can't be blank"],
               cpf: ["can't be blank"],
               gender: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        entity_id: :invalid,
        name: :invalid,
        cpf: :invalid,
        gender: 1
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               entity_id: ["is invalid"],
               name: ["is invalid"],
               cpf: ["is invalid"],
               gender: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        name: String.duplicate("a", 256),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"]
             }
    end

    test "filters cpf digit characters" do
      cpf = BrazilianDocuments.generate_cpf()
      {:ok, formatted_cpf} = BrazilianDocuments.format_cpf(cpf)

      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: formatted_cpf,
        gender: random_enum_value(:gender)
      }

      assert changeset = Individual.create_changeset(attrs)

      assert changeset.valid?
      assert changeset.changes.cpf == %CPF{number: cpf}
    end

    test "invalid cpf" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        name: Faker.Person.name(),
        cpf: "00887718061",
        gender: random_enum_value(:gender)
      }

      assert changeset = Individual.create_changeset(attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["is invalid"]}
    end

    test "[cpf, org_id] unique constraint" do
      cpf = BrazilianDocuments.generate_cpf()

      org = insert(:org)
      insert(:individual, org: org, cpf: cpf)

      entity = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        entity_id: entity.id,
        name: Faker.Person.name(),
        cpf: cpf,
        gender: random_enum_value(:gender)
      }

      assert {:error, changeset} =
               attrs
               |> Individual.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has already been taken"]}
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

    test "ignores non permitted attrs" do
      individual = insert(:individual, gender: :female)

      attrs = %{
        name: "New Name",
        cpf: BrazilianDocuments.generate_cpf(),
        gender: :other,
        org_id: UUID.generate()
      }

      assert changeset = Individual.update_changeset(individual, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               name: attrs[:name],
               gender: attrs[:gender]
             }
    end
  end
end
