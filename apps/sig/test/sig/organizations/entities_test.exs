defmodule Sig.Organizations.EntitiesTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities
  alias Sig.Organizations.Entities.{Entity, Individual}
  alias Sig.Organizations.Entities.Individual.Gender

  describe "create_organization_individual/2" do
    test "creates an individual with an entity" do
      organization = insert(:organization)

      attrs = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      assert {:ok, individual} = Entities.create_organization_individual(organization.id, attrs)

      assert Repo.get_by(Individual,
               entity_id: individual.entity_id,
               organization_id: organization.id,
               cpf: attrs.cpf,
               name: attrs.name,
               gender: attrs.gender
             )

      assert Repo.get(Entity, individual.entity_id)
    end

    test "invalid attrs" do
      organization = insert(:organization)

      assert {:error, changeset} = Entities.create_organization_individual(organization.id, %{})

      assert errors_on(changeset) == %{
               cpf: ["can't be blank"],
               gender: ["can't be blank"],
               name: ["can't be blank"]
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

  describe "list_organization_individuals/1" do
    test "list individuals from an organization" do
      organization = insert(:organization)
      individuals = insert_list(2, :individual, organization: organization)

      assert return = Entities.list_organization_individuals(organization.id)

      assert Enum.count(return) == 2

      returned_ids = Enum.map(return, & &1.entity_id)

      assert Enum.all?(individuals, &(&1.entity_id in returned_ids))
    end

    test "do not list individulas from a different organization" do
      organization = insert(:organization)
      insert(:individual, organization: organization)

      another_organization = insert(:organization)

      assert Entities.list_organization_individuals(another_organization.id) == []
    end
  end
end
