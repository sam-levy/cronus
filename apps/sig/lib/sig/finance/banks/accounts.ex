defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Organizations.Org
  alias Sig.Repo

  def list_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def list_active_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_active: true)
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def fetch_entity_primary(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_primary: true)
    |> Repo.one()
    |> handle_return()
  end

  def fetch_in_org_with_entity(%Org{} = org, id) do
    Account
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> join(:left, [account], entity in assoc(account, :entity))
    |> preload([_account, entity], entity: entity)
    |> Repo.one()
    |> handle_return()
  end

  defp query_by_entity(entity) do
    Account
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end

  defp handle_return(%Account{} = account), do: {:ok, account}
  defp handle_return(nil), do: {:error, :not_found}
end
