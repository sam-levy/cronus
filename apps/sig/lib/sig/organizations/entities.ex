defmodule Sig.Organizations.Entities do
  alias Ecto.Multi

  alias Sig.Organizations.Entities.{Entity, Individual}
  alias Sig.Repo

  def create_individual(attrs) do
    Multi.new()
    |> Multi.insert(:create_entity, %Entity{})
    |> Multi.insert(:create_individual, fn %{create_entity: entity} ->
      attrs
      |> Map.put(:entity_id, entity.id)
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
