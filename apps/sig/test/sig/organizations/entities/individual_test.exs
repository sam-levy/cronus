defmodule Sig.Organizations.Entities.IndividualTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Individual
  alias Sig.Organizations.Entities.Individual.Gender

  describe "new_changeset/2" do
    test "valid params" do
      params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      assert changeset.valid?

      assert changeset.changes == %{
               name: params[:name],
               cpf: params[:cpf],
               gender: String.to_atom(params[:gender])
             }
    end

    test "missing required params" do
      assert changeset = Individual.new_changeset(%Individual{}, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               cpf: ["can't be blank"],
               gender: ["can't be blank"]
             }
    end

    test "invalid params types" do
      params = %{
        name: :invalid,
        cpf: :invalid,
        gender: 1
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["is invalid"],
               cpf: ["is invalid"],
               gender: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      params = %{
        name: String.duplicate("a", 256),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["should be at most 255 character(s)"]}
    end

    test "invalid cpf" do
      params = %{
        name: Faker.Person.name(),
        cpf: "123",
        gender: random_enum_value(Gender)
      }

      assert changeset = Individual.new_changeset(%Individual{}, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{cpf: ["has invalid cpf"]}
    end

    test "cpf unique constraint" do
      entity = insert(:entity)

      cpf = BrazilianDocuments.generate_cpf()
      insert(:individual, cpf: cpf)

      params = %{
        name: Faker.Person.name(),
        cpf: cpf,
        gender: random_enum_value(Gender)
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
      params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      assert {:error, changeset} =
        %Individual{}
        |> Individual.new_changeset(params)
        |> put_change(:entity_id, UUID.generate())
        |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{entity: ["does not exist"]}
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
        gender: :other
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
