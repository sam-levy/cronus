defmodule Sig.Finance.Banks.EntityBankAccounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts.Create
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Finance.Banks.EntityBankAccounts.Update
  alias Sig.Repo

  defdelegate create(entity, attrs), to: Create, as: :call
  defdelegate update(eba, attrs), to: Update, as: :call

  def create_change(%{} = attrs \\ %{}) do
    EntityBankAccount.create_changeset(attrs)
  end

  def update_change(%EntityBankAccount{} = account, %{} = attrs \\ %{}) do
    EntityBankAccount.update_changeset(account, attrs)
  end

  def list_by_entity_with_account(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> preload_bank_account()
    |> order_by([bank_account: a], a.routing_number)
    |> Repo.all()
  end

  def list_active_by_entity_with_account(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> preload_bank_account()
    |> where([bank_account: a], a.is_active)
    |> order_by([bank_account: a], a.routing_number)
    |> Repo.all()
  end

  def list_active_by_entity_with_holder(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> preload_bank_account()
    |> preload_bank_account_holder()
    |> where([bank_account: a], a.is_active)
    |> order_by([bank_account: a], a.routing_number)
    |> Repo.all()
  end

  def get_with_holder(%Entity{} = entity, bank_account_id) when is_binary(bank_account_id) do
    entity
    |> query_by_entity()
    |> preload_bank_account()
    |> preload_bank_account_holder()
    |> where([eba: eba], eba.bank_account_id == ^bank_account_id)
    |> Repo.one()
  end

  def fetch_entity_primary(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> preload_bank_account()
    |> where([eba: eba], eba.is_primary)
    |> Repo.one()
    |> case do
      %EntityBankAccount{} = eba -> {:ok, eba}
      nil -> {:error, :not_found}
    end
  end

  def entities_relationships(%Entity{type: :individual}, %Entity{type: :individual}) do
    EntityBankAccount.individuals_relationships()
  end

  def entities_relationships(%Entity{type: :company}, %Entity{type: :individual}) do
    EntityBankAccount.individual_company_relationships()
  end

  def entities_relationships(%Entity{type: :individual}, %Entity{type: :company}) do
    EntityBankAccount.individual_company_relationships()
  end

  def entities_relationships(%Entity{type: :company}, %Entity{type: :company}) do
    EntityBankAccount.companies_relationships()
  end

  def subscribe_to_entity_bank_accounts(%Entity{} = entity) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(entity))
  end

  def broadcast_entity_bank_accounts(%Entity{} = entity) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(entity),
      {:updated_entity_bank_accounts, list_by_entity_with_account(entity)}
    )
  end

  defp topic(%Entity{} = entity), do: "entity_id:" <> entity.id <> ":entity_bank_accounts"

  defp query_by_entity(entity) do
    from(eba in EntityBankAccount, as: :eba)
    |> where([eba: eba], eba.org_id == ^entity.org_id)
    |> where([eba: eba], eba.entity_id == ^entity.id)
  end

  defp preload_bank_account(queryable) do
    queryable
    |> join(:left, [eba: eba], bank_account in assoc(eba, :bank_account), as: :bank_account)
    |> preload([bank_account: bank_account], bank_account: bank_account)
  end

  defp preload_bank_account_holder(queryable) do
    queryable
    |> join(:left, [bank_account: a], holder_entity in assoc(a, :entity), as: :holder_entity)
    |> join(:left, [holder_entity: e], individual in assoc(e, :individual), as: :holder_individual)
    |> join(:left, [holder_entity: e], company in assoc(e, :company), as: :holder_company)
    |> preload(
      [
        bank_account: bank_account,
        holder_entity: holder_entity,
        holder_individual: holder_individual,
        holder_company: holder_company
      ],
      bank_account:
        {bank_account,
         entity: {holder_entity, individual: holder_individual, company: holder_company}}
    )
  end
end
