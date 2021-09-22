defmodule Sig.Finance.Banks.EntityBankAccounts do
  import Ecto.Query

  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def list_by_entity_with_account(org_id, entity_id) do
    EntityBankAccount
    |> where(org_id: ^org_id)
    |> where(entity_id: ^entity_id)
    |> join(:left, [eba], bank_account in assoc(eba, :bank_account))
    |> preload([_eba, bank_account], bank_account: bank_account)
    |> order_by(:inserted_at)
    |> Repo.all()
  end
end
