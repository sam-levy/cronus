defmodule Sig.HR.Registrations do
  import Ecto.Query

  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.Create
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations
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

  def list_by_individual(%Individual{} = individual) do
    individual
    |> query_by_individual()
    |> preload_work_at()
    |> preload_registered_at()
    |> preload_salaries()
    |> order_by(:admission_date)
    |> Repo.all()
    |> handle_salary_amount()
  end

  def get(%Individual{} = individual, id) when is_binary(id) do
    individual
    |> query_by_individual()
    |> Organizations.preload_org()
    |> where(id: ^id)
    |> preload_salaries()
    |> Repo.one()
  end

  def get_by(attrs), do: Repo.get_by(Registration, attrs)

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

  defp preload_salaries(queryable) do
    queryable
    |> join(:left, [registration], salaries in assoc(registration, :salaries), as: :salaries)
    |> preload([_registration, salaries: salaries], salaries: salaries)
  end

  defp handle_salary_amount(registrations) when is_list(registrations) do
    Enum.map(registrations, &handle_salary_amount/1)
  end

  defp handle_salary_amount(%Registration{salaries: []} = registration), do: registration

  defp handle_salary_amount(%Registration{salaries: [salary]} = registration) do
    %{registration | salary_amount: salary.amount}
  end

  defp handle_salary_amount(%Registration{salaries: salaries} = registration) do
    [salary | _] = Enum.sort_by(salaries, & &1.start_date, {:desc, Date})

    %{registration | salary_amount: salary.amount}
  end
end
