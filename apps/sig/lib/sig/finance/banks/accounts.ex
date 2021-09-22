defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Repo

  def list_by_entity(%Entity{} = entity) do
    Account
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
    |> order_by(:inserted_at)
    |> Repo.all()
  end
end
