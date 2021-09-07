defmodule Sig.Organizations.Entities.EntityTest do
  use Sig.DataCase

  alias Sig.Organizations.Entities.Entity
  alias Sig.Organizations.Entities.Individual.Gender

  describe "new_individual_changeset/1" do
    test "valid params" do
      organzation_id = UUID.generate()

      individual_params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      entity_params = %{
        organization_id: organzation_id,
        individual: individual_params
      }

      assert changeset = Entity.new_individual_changeset(entity_params)

      assert changeset.valid?

      assert %{
        organization_id: ^organzation_id,
        individual: individual_changeset
      } = changeset.changes

      assert individual_changeset.changes == %{
               name: individual_params[:name],
               cpf: individual_params[:cpf],
               gender: String.to_atom(individual_params[:gender])
             }
    end

    test "missing required params" do
      assert changeset = Entity.new_individual_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               organization_id: ["can't be blank"],
               individual: ["can't be blank"]
             }
    end

    test "organization assoc constraint" do
      individual_params = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      entity_params = %{
        organization_id: UUID.generate(),
        individual: individual_params
      }

      assert {:error, changeset} =
        entity_params
        |> Entity.new_individual_changeset()
        |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{organization: ["does not exist"]}
    end
  end
end
