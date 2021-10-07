defmodule Sig.HR.Registrations do
  import Ecto.Query

  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.Create
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  defdelegate create(org, individual, attrs), to: Create, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Registration.create_changeset(attrs)
  end

  def update_change(%Registration{} = registration, %{} = attrs \\ %{}) do
    Registration.update_changeset(registration, attrs)
  end

  def resignation_change(%Registration{} = registration, %{} = attrs \\ %{}) do
    Registration.resignation_changeset(registration, attrs)
  end

  def update(%Registration{} = registration, %{} = attrs) do
    registration
    |> Registration.update_changeset(attrs)
    |> Repo.update()
  end

  # TODO: Join and preload salaries
  def list_by_individual(%Individual{} = individual) do
    individual
    |> query_by_individual()
    |> preload_work_at()
    |> preload_registered_at()
    |> order_by(:admission_date)
    |> Repo.all()
  end

  def fetch(%Individual{} = individual, id) when is_binary(id) do
    individual
    |> query_by_individual()
    |> where(id: ^id)
    |> Repo.one()
    |> case do
      %Registration{} = registration -> {:ok, registration}
      nil -> {:error, :not_found}
    end
  end

  def subscribe_to_individual_registrations(%Individual{} = individual) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(individual))
  end

  def broadcast_individual_registrations(%Individual{} = individual) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(individual),
      {:updated_individual_registrations, list_by_individual(individual)}
    )
  end

  defp topic(%Individual{} = individual) do
    "individual_id:" <> individual.entity_id <> ":registrations"
  end

  defp query_by_individual(individual) do
    Registration
    |> where(org_id: ^individual.org_id)
    |> where(individual_id: ^individual.entity_id)
  end

  defp preload_work_at(queryable) do
    queryable
    |> join(:left, [registration], work_at in assoc(registration, :work_at), as: :work_at)
    |> preload([_registration, work_at: work_at], work_at: work_at)
  end

  defp preload_registered_at(queryable) do
    queryable
    |> join(:left, [registration], registered_at in assoc(registration, :registered_at),
      as: :registered_at
    )
    |> preload([_registration, registered_at: registered_at], registered_at: registered_at)
  end
end
