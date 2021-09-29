defmodule Sig.Entities.Individuals do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals.Individual
  alias Sig.Documents
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create_individual_change(%{} = attrs \\ %{}) do
    Individual.create_changeset(attrs)
  end

  def list_individuals(%Org{} = org) do
    org
    |> individual_base_query()
    |> order_by(:name)
    |> Repo.all()
  end

  def get_individual(%Org{} = org, entity_id) when is_binary(entity_id) do
    org
    |> individual_base_query()
    |> where(entity_id: ^entity_id)
    |> Repo.one()
  end

  def fetch_individual_by_cpf(%Org{} = org, cpf) when is_binary(cpf) do
    cpf = Documents.raw_digits(cpf)

    if BrazilianDocuments.valid_cpf?(cpf) do
      Individual
      |> where(org_id: ^org.id)
      |> where(cpf: ^cpf)
      |> Repo.one()
      |> as_result()
    else
      {:error, "CPF inválido"}
    end
  end

  def create_individual(%Org{} = org, %{} = attrs) do
    Multi.new()
    |> Multi.insert(:create_entity, %Entity{org_id: org.id, type: :individual})
    |> Multi.insert(:create_individual, fn %{create_entity: entity} ->
      attrs
      |> Map.put(:org_id, org.id)
      |> Map.put(:entity_id, entity.id)
      |> Individual.create_changeset()
    end)
    |> Repo.transaction()
    |> as_result()
  end

  def update_individual(%Individual{} = individual, %{} = attrs) do
    individual
    |> Individual.update_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_individuals(%Org{} = org) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(org))
  end

  def broadcast_individuals(%Org{} = org) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(org),
      {:updated_individuals, list_individuals(org)}
    )
  end

  defp topic(%Org{} = org), do: "org_id:" <> org.id <> ":individuals"

  defp individual_base_query(org) do
    Individual
    |> where(org_id: ^org.id)
    |> join(:left, [individual], entity in assoc(individual, :entity))
    |> preload([_individual, entity], entity: entity)
  end

  defp as_result(%Individual{} = individual), do: {:ok, individual}
  defp as_result({:ok, %{create_individual: individual}}), do: {:ok, individual}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
  defp as_result(nil), do: {:error, :not_found}
end
