defmodule Sig.Finance.Banks.EntityBankAccounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts.Create
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Finance.Banks.EntityBankAccounts.Update
  alias Sig.Repo

  defdelegate create(entity, attrs), to: Create, as: :call
  defdelegate update(eba, attrs), to: Update, as: :call

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

  def fetch_entity_primary(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_primary: true)
    |> Repo.one()
    |> case do
      %EntityBankAccount{} = eba -> {:ok, eba}
      nil -> {:error, :not_found}
    end
  end

  defp query_by_entity(entity) do
    EntityBankAccount
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end
end
