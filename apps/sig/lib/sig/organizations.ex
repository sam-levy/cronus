defmodule Sig.Organizations do
  alias Sig.Organizations.Org
  alias Sig.Repo

  def fetch_org(org_id) do
    case Repo.get(Org, org_id) do
      %Org{} = org -> {:ok, org}
      nil -> {:error, :not_found}
    end
  end
end
