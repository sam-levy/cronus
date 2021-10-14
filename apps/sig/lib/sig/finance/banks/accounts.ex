defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.Create
  alias Sig.Finance.Banks.Accounts.Update
  alias Sig.Organizations.Org
  alias Sig.Repo

  defdelegate create(entity, attrs), to: Create, as: :call
  defdelegate update(account, attrs), to: Update, as: :call

  def create_change(%{} = attrs \\ %{}) do
    Account.create_changeset(attrs)
  end

  def update_change(%Account{} = account, %{} = attrs \\ %{}) do
    Account.update_changeset(account, attrs)
  end

  def list_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> order_by(:routing_number)
    |> Repo.all()
  end

  def list_active_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_active: true)
    |> order_by(:routing_number)
    |> Repo.all()
  end

  def fetch_entity_primary(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_primary: true)
    |> Repo.one()
    |> handle_return()
  end

  def fetch_in_org_with_entity(%Org{} = org, id) when is_binary(id) do
    Account
    |> where(org_id: ^org.id)
    |> where(id: ^id)
    |> join(:left, [account], entity in assoc(account, :entity))
    |> preload([_account, entity], entity: entity)
    |> Repo.one()
    |> handle_return()
  end

  def fetch(%Entity{} = entity, id) do
    entity
    |> query_by_entity()
    |> where(id: ^id)
    |> Repo.one()
    |> handle_return()
  end

  def subscribe_to_bank_accounts(%Entity{} = entity) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(entity))
  end

  def broadcast_bank_accounts(%Entity{} = entity) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(entity),
      {:updated_bank_accounts, list_by_entity(entity)}
    )
  end

  defp topic(%Entity{} = entity), do: "entity_id:" <> entity.id <> ":bank_accounts"

  defp query_by_entity(entity) do
    Account
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end

  defp handle_return(%Account{} = account), do: {:ok, account}
  defp handle_return(nil), do: {:error, :not_found}
end
