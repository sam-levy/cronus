defmodule Sig.Finance.Banks.Accounts.Create do
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
    |> Multi.run(:existing_primary_account, fn repo, _ ->
      entity
      |> Accounts.fetch_entity_primary()
      |> handle_existing_primary_account(attrs, repo)
    end)
    |> Multi.run(:existing_primary_eba, fn repo, _ ->
      entity
      |> EntityBankAccounts.fetch_entity_primary()
      |> handle_existing_primary_eba(attrs, repo)
    end)
    |> Multi.insert(:create_account, &account_changeset(&1, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp handle_existing_primary_account({:error, :not_found}, _attrs, _repo), do: {:ok, nil}

  defp handle_existing_primary_account({:ok, account}, %{is_primary: true}, repo) do
    account
    |> Account.update_changeset(%{is_primary: false})
    |> repo.update()
  end

  defp handle_existing_primary_account({:ok, account}, _attrs, _repo), do: {:ok, account}

  defp handle_existing_primary_eba({:error, :not_found}, _attrs, _repo), do: {:ok, nil}

  defp handle_existing_primary_eba({:ok, eba}, %{is_primary: true}, repo) do
    eba
    |> EntityBankAccount.update_changeset(%{is_primary: false})
    |> repo.update()
  end

  defp handle_existing_primary_eba({:ok, eba}, _attrs, _repo), do: {:ok, eba}

  defp account_changeset(%{existing_primary_account: nil, existing_primary_eba: nil}, attrs) do
    attrs
    |> Map.put(:is_primary, true)
    |> Account.create_changeset()
  end

  defp account_changeset(_, attrs), do: Account.create_changeset(attrs)

  defp as_result({:ok, %{create_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
