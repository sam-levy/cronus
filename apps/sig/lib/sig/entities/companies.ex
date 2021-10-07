defmodule Sig.Entities.Companies do
  import Ecto.Query

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

  def list(%Org{} = org) do
    Company
    |> where(org_id: ^org.id)
    |> order_by(:trade_name)
    |> Repo.all()
  end
end
