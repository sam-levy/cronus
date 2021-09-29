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
    |> join(:left, [eba], bank_account in assoc(eba, :bank_account))
    |> preload([_eba, bank_account], bank_account: bank_account)
    |> order_by([_eba, bank_account], bank_account.routing_number)
    |> Repo.all()
  end

  def get_with_holder(%Entity{} = entity, bank_account_id) do
    entity
    |> query_by_entity()
    |> where(bank_account_id: ^bank_account_id)
    |> join(:left, [eba], bank_account in assoc(eba, :bank_account), as: :account)
    |> join(:left, [eba, account: a], holder_entity in assoc(a, :entity), as: :holder_entity)
    |> join(:left, [eba, holder_entity: e], individual in assoc(e, :individual),
      as: :holder_individual
    )
    |> join(:left, [eba, holder_entity: e], company in assoc(e, :company), as: :holder_company)
    |> preload(
      [
        _eba,
        account: account,
        holder_entity: holder_entity,
        holder_individual: holder_individual,
        holder_company: holder_company
      ],
      bank_account:
        {account, entity: {holder_entity, individual: holder_individual, company: holder_company}}
    )
    |> Repo.one()
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
    EntityBankAccount
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end
end
