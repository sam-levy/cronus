defmodule Sig.Finance.Banks.EntityBankAccounts do
  import Ecto.Query

  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def list_by_entity(org_id, entity_id) do
    EntityBankAccount
    |> where(org_id: ^org_id)
    |> where(entity_id: ^entity_id)
    |> order_by(:inserted_at)
    |> Repo.all()
  end
end
