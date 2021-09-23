defmodule Sig.Finance.Banks.Accounts.Update do
  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def call(%Entity{} = entity, %Account{} = account, %{} = attrs) do
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
    |> Multi.update(:update_account, &account_changeset(&1, account, attrs))
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

  defp account_changeset(
         %{existing_primary_account: nil, existing_primary_eba: nil},
         account,
         attrs
       ) do
    attrs = Map.put(attrs, :is_primary, true)

    Account.update_changeset(account, attrs)
  end

  defp account_changeset(_, account, attrs), do: Account.update_changeset(account, attrs)

  defp as_result({:ok, %{update_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
