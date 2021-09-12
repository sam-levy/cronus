defmodule Sig.Entities.IndividualsTest do
  use Sig.DataCase

  import Phoenix.ChannelTest

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals
  alias Sig.Entities.Individuals.Individual
  alias Sig.Entities.Individuals.Individual.Gender

  @endpoint SigLive.Endpoint

  describe "cast_individual_params/1" do
    test "cast params" do
      params = %{
        "cpf" => BrazilianDocuments.generate_cpf(),
        "name" => Faker.Person.name(),
        "gender" =>  random_enum_value(Gender)
      }

      assert Individuals.cast_individual_params(params) == %{
        cpf: %CPF{number: params["cpf"]},
        name: params["name"],
        gender: String.to_atom(params["gender"]),
      }
    end
  end

  describe "individual_change/1" do
    test "returns Individual changeset" do
      assert %Ecto.Changeset{data: %Individual{}} = Individuals.individual_change()

      assert %Ecto.Changeset{data: %Individual{}} =
               Individuals.individual_change(%{name: Faker.Company.name()})
    end
  end

  describe "list_organization_individuals/1" do
    test "list individuals from an organization" do
      organization = insert(:organization)
      individuals = insert_list(2, :individual, organization: organization)

      assert return = Individuals.list_organization_individuals(organization.id)

      assert Enum.count(return) == 2

      returned_ids = Enum.map(return, & &1.entity_id)

      assert Enum.all?(individuals, &(&1.entity_id in returned_ids))
    end

    test "do not list individulas from a different organization" do
      organization = insert(:organization)
      insert(:individual, organization: organization)

      another_organization = insert(:organization)

      assert Individuals.list_organization_individuals(another_organization.id) == []
    end
  end

  describe "fetch_individual_by_cpf/2" do
    test "fetches individual by cpf" do
      cpf = BrazilianDocuments.generate_cpf()
      organization = insert(:organization)

      individual = insert(:individual, cpf: cpf, organization: organization)

      insert(:individual, organization: organization)
      insert(:individual)

      assert {:ok, return} = Individuals.fetch_individual_by_cpf(organization.id, cpf)

      assert return.entity_id == individual.entity_id
      assert return.cpf == %CPF{number: individual.cpf}
      assert return.organization_id == individual.organization.id
    end

    test "wrong organization" do
      cpf = BrazilianDocuments.generate_cpf()
      right_organization = insert(:organization)
      wrong_organization = insert(:organization)

      insert(:individual, cpf: cpf, organization: right_organization)

      assert Individuals.fetch_individual_by_cpf(wrong_organization.id, cpf) == {:error, :not_found}
    end

    test "wrong cpf" do
      cpf = BrazilianDocuments.generate_cpf()
      right_organization = insert(:organization)
      wrong_organization = insert(:organization)

      _right_individual = insert(:individual, cpf: cpf, organization: right_organization)
      wrong_individual = insert(:individual, organization: wrong_organization)

      assert Individuals.fetch_individual_by_cpf(right_organization.id, wrong_individual.cpf) == {:error, :not_found}
    end
  end

  describe "create_individual/2" do
    test "creates an individual with an entity" do
      organization = insert(:organization)

      attrs = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(Gender)
      }

      assert {:ok, individual} = Individuals.create_individual(organization.id, attrs)

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

      assert {:error, changeset} = Individuals.create_individual(organization.id, %{})

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

      assert {:ok, _return} = Individuals.update_individual(individual, attrs)

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

      assert {:error, changeset} = Individuals.update_individual(individual, attrs)

      assert errors_on(changeset) == %{
               gender: ["is invalid"]
             }
    end
  end

  describe "subscribe_to_organization_individuals/1" do
    test "subscribes to organization individuals topic" do
      organization = insert(:organization)
      topic = "organization_id:" <> organization.id <> ":individuals"

      assert Individuals.subscribe_to_organization_individuals(organization.id) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_organization_individuals, :individuals})

      assert_receive {:updated_organization_individuals, :individuals}
    end
  end

  describe "broadcast_organization_individuals/1" do
    test "broadcasts individuals from an organization" do
      organization = insert(:organization)
      individuals = insert_list(2, :individual, organization: organization)
      _wrong_individuals = insert_list(2, :individual)

      topic = "organization_id:" <> organization.id <> ":individuals"

      @endpoint.subscribe(topic)

      assert Individuals.broadcast_organization_individuals(organization.id) == :ok

      assert_receive {:updated_organization_individuals, received_individuals}

      assert Enum.count(received_individuals) == 2

      Enum.each(individuals, fn individual ->
        assert received_individual = Enum.find(received_individuals, & &1.entity_id == individual.entity_id)

        assert received_individual.organization_id == individual.organization_id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
