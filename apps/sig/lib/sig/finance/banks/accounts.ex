defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query
  import Sig.Broadcaster

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

  def list_by(schema, opts \\ [])
  def list_by(%Org{} = schema, opts), do: do_list_by(schema, opts)
  def list_by(%Entity{} = schema, opts), do: do_list_by(schema, opts)

  defp do_list_by(schema, opts) do
    schema
    |> query_by()
    |> apply_where(opts)
    |> order_by(:routing_number)
    |> Repo.all()
  end

  defp apply_where(queryable, opts) do
    case Keyword.get(opts, :where) do
      nil ->
        queryable

      clauses ->
        Enum.reduce(clauses, queryable, fn clause, acc ->
          where(acc, ^[clause])
        end)
    end
  end

  def fetch_entity_primary(%Entity{} = entity) do
    entity
    |> query_by()
    |> where(is_primary: true)
    |> Repo.one()
    |> handle_return()
  end

  # TODO: Add tests
  def fetch_entity_primary(org_id, entity_id) when is_binary(org_id) and is_binary(entity_id) do
    Account
    |> where(org_id: ^org_id)
    |> where(entity_id: ^entity_id)
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

  def fetch(%Entity{} = entity, id) when is_binary(id) do
    entity
    |> query_by()
    |> where(id: ^id)
    |> Repo.one()
    |> handle_return()
  end

  defp query_by(%Entity{} = entity) do
    Account
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end

  defp query_by(%Org{} = org) do
    Account |> where(org_id: ^org.id)
  end

  defp handle_return(%Account{} = account), do: {:ok, account}
  defp handle_return(nil), do: {:error, :not_found}

  def subscribe_to_bank_accounts(%Entity{} = entity), do: subscribe(topic(entity))

  def broadcast_bank_accounts(%Entity{} = entity) do
    broadcast(topic(entity), {:updated_bank_accounts, list_by(entity)})
  end

  defp topic(%Entity{} = entity), do: "entity_id:" <> entity.id <> ":bank_accounts"
end
