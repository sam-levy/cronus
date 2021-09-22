defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Repo

  def list_by_entity(org_id, entity_id) do
    Account
    |> where(org_id: ^org_id)
    |> where(entity_id: ^entity_id)
    |> order_by(:inserted_at)
    |> Repo.all()
  end
end
