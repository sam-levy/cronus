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
    |> Multi.run(:existing_primary_account, fn _, _ ->
      {:ok, Accounts.get_entity_primary(entity)}
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      {:ok, EntityBankAccounts.get_entity_primary(entity)}
    end)
    |> Multi.merge(&update_existing_account(&1, attrs))
    |> Multi.merge(&update_existing_eba(&1, attrs))
    |> Multi.insert(:create_account, &account_changeset(&1, attrs))
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

  defp account_changeset(%{existing_primary_account: nil, existing_primary_eba: nil}, attrs) do
    attrs
    |> Map.put(:is_primary, true)
    |> Account.create_changeset()
  end

  defp account_changeset(_, attrs), do: Account.create_changeset(attrs)

  defp as_result({:ok, %{create_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
