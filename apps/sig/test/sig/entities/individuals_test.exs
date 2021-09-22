defmodule Sig.Entities.IndividualsTest do
  use Sig.DataCase

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals
  alias Sig.Entities.Individuals.Individual

  @endpoint SigLive.Endpoint

  describe "cast_individual_params/1" do
    test "cast params" do
      params = %{
        "cpf" => BrazilianDocuments.generate_cpf(),
        "name" => Faker.Person.name(),
        "gender" => random_enum_value(:gender)
      }

      assert Individuals.cast_individual_params(params) == %{
               cpf: %CPF{number: params["cpf"]},
               name: params["name"],
               gender: String.to_atom(params["gender"])
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

  describe "list_individuals/1" do
    test "lists individuals from an org ordered by name" do
      org = insert(:org)

      insert(:individual, name: "Bugs Bunny", org: org)
      insert(:individual, name: "Daffy Duck", org: org)

      assert [%Individual{name: "Bugs Bunny"}, %Individual{name: "Daffy Duck"}] =
               Individuals.list_individuals(org.id)
    end

    test "do not list individuals from another org" do
      org = insert(:org)
      insert(:individual, org: org)

      another_org = insert(:org)

      assert Individuals.list_individuals(another_org.id) == []
    end
  end

  describe "fetch_individual_by_cpf/2" do
    test "fetches individual by cpf" do
      cpf = BrazilianDocuments.generate_cpf()
      org = insert(:org)

      individual = insert(:individual, cpf: cpf, org: org)

      insert(:individual, org: org)
      insert(:individual)

      assert {:ok, return} = Individuals.fetch_individual_by_cpf(org.id, cpf)

      assert return.entity_id == individual.entity_id
      assert return.cpf == %CPF{number: individual.cpf}
      assert return.org_id == individual.org.id
    end

    test "do not fetch individual from another org" do
      cpf = BrazilianDocuments.generate_cpf()
      right_org = insert(:org)
      wrong_org = insert(:org)

      insert(:individual, cpf: cpf, org: right_org)

      assert Individuals.fetch_individual_by_cpf(wrong_org.id, cpf) ==
               {:error, :not_found}
    end

    test "do not fetch individual with another cpf" do
      cpf = BrazilianDocuments.generate_cpf()
      right_org = insert(:org)
      wrong_org = insert(:org)

      _right_individual = insert(:individual, cpf: cpf, org: right_org)
      wrong_individual = insert(:individual, org: wrong_org)

      assert Individuals.fetch_individual_by_cpf(right_org.id, wrong_individual.cpf) ==
               {:error, :not_found}
    end
  end

  describe "create_individual/2" do
    test "creates individual with entity" do
      org = insert(:org)

      attrs = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert {:ok, individual} = Individuals.create_individual(org.id, attrs)

      assert Repo.get_by(Individual,
               entity_id: individual.entity_id,
               org_id: org.id,
               cpf: attrs.cpf,
               name: attrs.name,
               gender: attrs.gender
             )

      assert Repo.get_by(Entity,
               id: individual.entity_id,
               org_id: org.id
             )
    end

    test "invalid attrs" do
      org = insert(:org)

      assert {:error, changeset} = Individuals.create_individual(org.id, %{})

      assert errors_on(changeset) == %{
               cpf: ["can't be blank"],
               gender: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "raises if org does not exist" do
      attrs = %{
        name: Faker.Person.name(),
        cpf: BrazilianDocuments.generate_cpf(),
        gender: random_enum_value(:gender)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Individuals.create_individual(UUID.generate(), attrs) end
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
               entity_id: individual.entity_id,
               org_id: individual.org_id,
               cpf: individual.cpf,
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

  describe "subscribe_to_individuals/1" do
    test "subscribes to individuals topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":individuals"

      assert Individuals.subscribe_to_individuals(org.id) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_org_individuals, :individuals}
      )

      assert_receive {:updated_org_individuals, :individuals}
    end
  end

  describe "broadcast_individuals/1" do
    test "broadcasts individuals from an organization" do
      org = insert(:org)
      individuals = insert_list(2, :individual, org: org)
      _wrong_individuals = insert_list(2, :individual)

      topic = "org_id:" <> org.id <> ":individuals"

      @endpoint.subscribe(topic)

      assert Individuals.broadcast_individuals(org.id) == :ok

      assert_receive {:updated_org_individuals, received_individuals}

      assert Enum.count(received_individuals) == 2

      Enum.each(individuals, fn individual ->
        assert received_individual =
                 Enum.find(received_individuals, &(&1.entity_id == individual.entity_id))

        assert received_individual.org_id == individual.org_id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
