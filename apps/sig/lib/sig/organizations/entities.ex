defmodule Sig.Organizations.Entities do
  import Ecto.Query

  alias Ecto.Multi
  alias Sig.Organizations.Entities.{Entity, Individual}
  alias Sig.Repo

  def list_organization_individuals(organization_id) do
    Individual
    |> where(organization_id: ^organization_id)
    |> Repo.all()
  end

  def create_organization_individual(organization_id, attrs) do
    Multi.new()
    |> Multi.insert(:create_entity, %Entity{})
    |> Multi.insert(:create_individual, fn %{create_entity: entity} ->
      attrs
      |> Map.put(:entity_id, entity.id)
      |> Map.put(:organization_id, organization_id)
      |> Individual.create_changeset()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_individual: individual}} -> {:ok, individual}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  def update_individual(%Individual{} = individual, attrs) do
    individual
    |> Individual.update_changeset(attrs)
    |> Repo.update()
  end
end
