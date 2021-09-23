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
    |> Multi.run(:existing_primary_account, fn _, _ ->
      {:ok, Accounts.get_entity_primary(entity)}
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      {:ok, EntityBankAccounts.get_entity_primary(entity)}
    end)
    |> Multi.merge(&update_existing_account(&1, attrs))
    |> Multi.merge(&update_existing_eba(&1, attrs))
    |> Multi.update(:update_account, &account_changeset(&1, account, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp update_existing_account(%{existing_primary_account: nil}, _attrs), do: Multi.new()

  defp update_existing_account(
         %{existing_primary_account: existing_primary_account},
         %{is_primary: true} = _attrs
       ) do
    changeset = Account.update_changeset(existing_primary_account, %{is_primary: false})

    Multi.update(Multi.new(), :update_existing_account, changeset)
  end

  defp update_existing_account(_changes, _attrs), do: Multi.new()

  defp update_existing_eba(%{existing_primary_eba: nil}, _attrs), do: Multi.new()

  defp update_existing_eba(
         %{existing_primary_eba: existing_primary_eba},
         %{is_primary: true} = _attrs
       ) do
    changeset = EntityBankAccount.update_changeset(existing_primary_eba, %{is_primary: false})

    Multi.update(Multi.new(), :update_existing_eba, changeset)
  end

  defp update_existing_eba(_changes, _attrs), do: Multi.new()

  defp account_changeset(%{existing_primary_account: nil, existing_primary_eba: nil}, account, attrs) do
    attrs = Map.put(attrs, :is_primary, true)

    Account.update_changeset(account, attrs)
  end

  defp account_changeset(_, account, attrs), do: Account.update_changeset(account, attrs)

  defp as_result({:ok, %{update_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
