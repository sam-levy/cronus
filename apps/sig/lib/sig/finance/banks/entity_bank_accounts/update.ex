defmodule Sig.Finance.Banks.EntityBankAccounts.Update do
  alias Ecto.Multi

  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def call(%EntityBankAccount{} = eba, %{} = attrs) do
    %{entity: entity} = Repo.preload(eba, :entity)

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
    |> Multi.update(:update_eba, &eba_changeset(&1, eba, attrs))
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

  defp eba_changeset(
         %{existing_primary_account: nil, existing_primary_eba: nil},
         eba,
         attrs
       ) do
    attrs = Map.put(attrs, :is_primary, true)

    EntityBankAccount.update_changeset(eba, attrs)
  end

  defp eba_changeset(_, eba, attrs), do: EntityBankAccount.update_changeset(eba, attrs)

  defp as_result({:ok, %{update_eba: eba}}), do: {:ok, eba}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
