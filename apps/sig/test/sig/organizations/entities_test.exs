defmodule Sig.Organizations.EntitiesTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities
  alias Sig.Organizations.Entities.{Entity, Individual}
  alias Sig.Organizations.Entities.Individual.Gender

  describe "create_individual/1" do
    test "creates an individual with and entity" do
      organization = insert(:organization)

      attrs = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender),
        organization_id: organization.id
      }

      assert {:ok, individual} = Entities.create_individual(attrs)

      assert Repo.get_by(Individual,
               entity_id: individual.entity_id,
               cpf: attrs.cpf,
               organization_id: attrs.organization_id,
               name: attrs.name,
               gender: attrs.gender
             )

      assert Repo.get(Entity, individual.entity_id)
    end

    test "invalid attrs" do
      assert {:error, changeset} = Entities.create_individual(%{})

      assert errors_on(changeset) == %{
               cpf: ["can't be blank"],
               gender: ["can't be blank"],
               name: ["can't be blank"],
               organization_id: ["can't be blank"]
             }
    end
  end

  describe "update_individual/2" do
    test "updates an individual" do
      individual = insert(:individual, gender: :male)

      attrs = %{
        name: "New Name",
        gender: :other
      }

      assert {:ok, _return} = Entities.update_individual(individual, attrs)

      assert Repo.get_by(Individual,
               cpf: individual.cpf,
               organization_id: individual.organization_id,
               name: attrs.name,
               gender: attrs.gender
             )
    end

    test "invalid attrs" do
      individual = insert(:individual, gender: :male)

      attrs = %{
        name: "New Name",
        gender: :invalid
      }

      assert {:error, changeset} = Entities.update_individual(individual, attrs)

      assert errors_on(changeset) == %{
               gender: ["is invalid"]
             }
    end
  end
end
