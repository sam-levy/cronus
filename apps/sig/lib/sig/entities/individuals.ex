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

  def list_organization_individuals(organization_id) do
    Individual
    |> where(organization_id: ^organization_id)
    |> Repo.all()
  end

  def fetch_individual_by_cpf(organization_id, cpf) do
    cpf =
      cpf
      |> String.trim()
      |> String.replace(~r/\D/, "")

    if BrazilianDocuments.valid_cpf?(cpf) do
      Individual
      |> where(organization_id: ^organization_id)
      |> where(cpf: ^cpf)
      |> Repo.one()
      |> as_result()
    else
      {:error, "CPF inválido"}
    end
  end

  def create_individual(organization_id, attrs) do
    Multi.new()
    |> Multi.insert(:create_entity, %Entity{})
    |> Multi.insert(:create_individual, fn %{create_entity: entity} ->
      attrs
      |> Map.put(:organization_id, organization_id)
      |> Map.put(:entity_id, entity.id)
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

  def subscribe_to_organization_individuals(organization_id) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(organization_id))
  end

  def broadcast_organization_individuals(organization_id) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(organization_id),
      {:updated_organization_individuals, list_organization_individuals(organization_id)}
    )
  end

  defp topic(organization_id), do: "organization_id:" <> organization_id <> ":individuals"

  defp as_result(%Individual{} = individual), do: {:ok, individual}
  defp as_result({:ok, %{create_individual: individual}}), do: {:ok, individual}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
  defp as_result(nil), do: {:error, :not_found}
end
