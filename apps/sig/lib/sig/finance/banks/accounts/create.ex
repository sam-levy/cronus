defmodule Sig.Finance.Banks.Accounts.Create do
  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.BackUpdater, as: AccountsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.BackUpdater, as: EBAsBackUpdater
  alias Sig.Repo

  def call(%Entity{} = entity, %{} = attrs) do
    attrs = assign_keys(attrs, entity)

    Multi.new()
    |> Multi.run(:existing_primary_account, fn _, _ ->
      AccountsBackUpdater.handle_existing_primary_account(entity, attrs)
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      EBAsBackUpdater.handle_existing_primary_eba(entity, attrs)
    end)
    |> Multi.insert(:create_account, &account_changeset(&1, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp assign_keys(attrs, entity) do
    attrs
    |> Map.put(:org_id, entity.org_id)
    |> Map.put(:entity_id, entity.id)
  end

  defp account_changeset(%{existing_primary_account: nil, existing_primary_eba: nil}, attrs) do
    attrs
    |> Map.put(:is_primary, true)
    |> Account.create_changeset()
  end

  defp account_changeset(_, attrs), do: Account.create_changeset(attrs)

  defp as_result({:ok, %{create_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
