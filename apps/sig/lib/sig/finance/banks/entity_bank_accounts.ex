defmodule Sig.Finance.Banks.EntityBankAccounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def list_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def list_by_entity_with_account(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> join(:left, [eba], bank_account in assoc(eba, :bank_account))
    |> preload([_eba, bank_account], bank_account: bank_account)
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  defp query_by_entity(entity) do
    EntityBankAccount
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end
end
