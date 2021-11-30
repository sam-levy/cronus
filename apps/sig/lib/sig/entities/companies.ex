defmodule Sig.Entities.Companies do
  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.Entities.Companies.Company
  alias Sig.Organizations.Org
  alias Sig.Repo

  def fetch(%Org{} = org, entity_id) when is_binary(entity_id) do
    Company
    |> where(org_id: ^org.id)
    |> where(entity_id: ^entity_id)
    |> Repo.one()
    |> case do
      %Company{} = company -> {:ok, company}
      nil -> {:error, :not_found}
    end
  end

  def get_by_registration_with_entity(%Registration{} = registration) do
    Company
    |> join(:left, [company], registration in Registration,
      on: registration.registered_at_id == company.entity_id
    )
    |> join(:left, [company, _r], entity in assoc(company, :entity))
    |> preload([_c, _r, entity], entity: entity)
    |> where([_c, r, _e], r.id == ^registration.id)
    |> where(org_id: ^registration.org_id)
    |> Repo.one()
  end

  def list(%Org{} = org, opts \\ []) do
    Company
    |> where(org_id: ^org.id)
    |> filter(opts)
    |> order_by(:trade_name)
    |> Repo.all()
  end

  defp filter(queryable, opts) do
    case Keyword.get(opts, :filter, []) do
      [] -> queryable
      filters -> where(queryable, ^filters)
    end
  end
end
