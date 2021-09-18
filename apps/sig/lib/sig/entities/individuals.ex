defmodule Sig.Entities.Individuals do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals.Individual
  alias Sig.Repo

  def cast_individual_params(params) do
    Individual.cast_params(params)
  end

  def individual_change(attrs \\ %{}) do
    Individual.create_changeset(attrs)
  end

  def list_individuals(org_id) do
    Individual
    |> where(org_id: ^org_id)
    |> order_by(:name)
    |> Repo.all()
  end

  def fetch_individual_by_cpf(org_id, cpf) do
    cpf =
      cpf
      |> String.trim()
      |> String.replace(~r/\D/, "")

    if BrazilianDocuments.valid_cpf?(cpf) do
      Individual
      |> where(org_id: ^org_id)
      |> where(cpf: ^cpf)
      |> Repo.one()
      |> as_result()
    else
      {:error, "CPF inválido"}
    end
  end

  def create_individual(org_id, attrs) do
    Multi.new()
    |> Multi.insert(:create_entity, %Entity{org_id: org_id})
    |> Multi.insert(:create_individual, fn %{create_entity: entity} ->
      attrs
      |> Map.put(:entity_id, entity.id)
      |> Map.put(:org_id, org_id)
      |> Individual.create_changeset()
    end)
    |> Repo.transaction()
    |> as_result()
  end

  def update_individual(%Individual{} = individual, attrs) do
    individual
    |> Individual.update_changeset(attrs)
    |> Repo.update()
  end

  def subscribe_to_individuals(org_id) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(org_id))
  end

  def broadcast_individuals(org_id) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(org_id),
      {:updated_org_individuals, list_individuals(org_id)}
    )
  end

  defp topic(org_id), do: "org_id:" <> org_id <> ":individuals"

  defp as_result(%Individual{} = individual), do: {:ok, individual}
  defp as_result({:ok, %{create_individual: individual}}), do: {:ok, individual}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
  defp as_result(nil), do: {:error, :not_found}
end
