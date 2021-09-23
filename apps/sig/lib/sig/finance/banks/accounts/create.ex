defmodule Sig.Finance.Banks.Accounts.Create do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def call(%Entity{} = entity, %{} = attrs) do
    attrs =
      attrs
      |> Map.put(:org_id, entity.org_id)
      |> Map.put(:entity_id, entity.id)

    Multi.new()
    |> Multi.run(:existing_accounts, fn _, _ -> fetch_existing_accounts(entity) end)
    |> Multi.run(:existing_ebas, fn _, _ -> fetch_existing_ebas(entity) end)
    |> Multi.merge(&update_existing_ebas(&1, attrs))
    |> Multi.merge(&update_existing_accounts(&1, attrs))
    |> Multi.insert(:create_account, &account_changeset(&1, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp fetch_existing_accounts(entity), do: {:ok, Accounts.list_by_entity(entity)}

  defp fetch_existing_ebas(entity), do: {:ok, EntityBankAccounts.list_by_entity(entity)}

  defp update_existing_ebas(%{existing_ebas: []}, _attrs), do: Multi.new()

  defp update_existing_ebas(_, %{is_primary: false} = _attrs), do: Multi.new()

  defp update_existing_ebas(%{existing_ebas: existing_ebas}, _attrs) do
    to_update =
      EntityBankAccount
      |> where([eba], eba.org_id in ^Enum.map(existing_ebas, & &1.org_id))
      |> where([eba], eba.bank_account_id in ^Enum.map(existing_ebas, & &1.bank_account_id))
      |> update(set: [is_primary: false])

    Multi.update_all(Multi.new(), :update_existing_entity_accounts, to_update, [])
  end

  defp update_existing_accounts(_, %{is_primary: false} = _attrs), do: Multi.new()

  defp update_existing_accounts(%{existing_accounts: []}, _attrs), do: Multi.new()

  defp update_existing_accounts(%{existing_accounts: existing_accounts}, _attrs) do
    to_update =
      Account
      |> where([account], account.org_id in ^Enum.map(existing_accounts, & &1.org_id))
      |> where([account], account.id in ^Enum.map(existing_accounts, & &1.id))
      |> update(set: [is_primary: false])

    Multi.update_all(Multi.new(), :update_existing_accounts, to_update, [])
  end

  def account_changeset(%{existing_accounts: [], existing_ebas: []}, attrs) do
    attrs
    |> Map.put(:is_primary, true)
    |> Account.create_changeset()
  end

  def account_changeset(_, attrs), do: Account.create_changeset(attrs)

  defp as_result({:ok, %{create_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
