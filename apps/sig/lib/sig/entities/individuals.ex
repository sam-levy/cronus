defmodule Sig.Entities.Individuals do
  use Sig.Query, schema: __MODULE__.Individual, as: :individual

  import Sig.Broadcaster

  alias Ecto.Multi

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Entity
  alias Sig.Entities.Individuals.Individual
  alias Sig.Documents
  alias Sig.Organizations.Org
  alias Sig.Repo

  @default_preloads [:entity]

  def create_individual_change(%{} = attrs \\ %{}) do
    Individual.create_changeset(attrs)
  end

  def list_individuals(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(@default_preloads)
    |> shallow_preload(opts)
    |> filter_by(opts)
    |> handle_order_by(opts, :name)
    |> Repo.all()
  end

  def get_individual(%Org{} = org, entity_id, opts \\ []) when is_binary(entity_id) do
    org
    |> query_by()
    |> where(entity_id: ^entity_id)
    |> shallow_preload(@default_preloads)
    |> shallow_preload(opts)
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

  def subscribe_to_individuals(%Org{} = org), do: subscribe(topic(org))

  def broadcast_individuals(%Org{} = org, opts \\ []) do
    broadcast(topic(org), {:updated_individuals, list_individuals(org, opts)})
  end

  defp topic(%Org{} = org), do: "org_id:" <> org.id <> ":individuals"

  defp query_by(%Org{} = org) do
    where(init_query(), org_id: ^org.id)
  end

  defp as_result(%Individual{} = individual), do: {:ok, individual}
  defp as_result({:ok, %{create_individual: individual}}), do: {:ok, individual}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
  defp as_result(nil), do: {:error, :not_found}

  @impl Sig.Query
  def shallow_preload(queryable, :active_registered_at_companies) do
    queryable
    |> join(
      :left_lateral,
      [individual: individual],
      r in fragment(
        "SELECT * FROM employee_registrations AS r WHERE r.org_id = ? AND r.individual_id = ? AND r.resignation_date IS NULL",
        individual.org_id,
        individual.entity_id
      ),
      as: :active_registrations
    )
    |> join(:left, [active_registrations: r], c in Company,
      on: c.entity_id == r.registered_at_id,
      as: :active_registered_at_companies
    )
    |> preload([active_registered_at_companies: c], registered_at_companies: c)
  end
end
