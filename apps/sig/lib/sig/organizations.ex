defmodule Sig.Organizations do
  import Ecto.Query

  alias Sig.Organizations.Org
  alias Sig.Organizations.Position
  alias Sig.Organizations.Sector
  alias Sig.Repo

  def fetch_org(org_id) when is_binary(org_id) do
    case Repo.get(Org, org_id) do
      %Org{} = org -> {:ok, org}
      nil -> {:error, :not_found}
    end
  end

  def get_org(org_id) when is_binary(org_id) do
    Repo.get(Org, org_id)
  end

  def list_sectors(%Org{} = org) do
    Sector
    |> where(org_id: ^org.id)
    |> order_by(:name)
    |> Repo.all()
  end

  def list_positions(%Org{} = org) do
    Position
    |> where(org_id: ^org.id)
    |> order_by(:name)
    |> Repo.all()
  end
end
