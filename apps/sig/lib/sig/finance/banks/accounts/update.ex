defmodule Sig.Finance.Banks.Accounts.Update do
  alias Ecto.Multi

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.BackUpdater, as: AccountsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.BackUpdater, as: EBAsBackUpdater
  alias Sig.Repo

  def call(%Account{} = account, %{} = attrs) do
    %{entity: entity} = Repo.preload(account, :entity)

    Multi.new()
    |> Multi.run(:existing_primary_account, fn _, _ ->
      AccountsBackUpdater.handle_existing_primary_account(entity, attrs)
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      EBAsBackUpdater.handle_existing_primary_eba(entity, attrs)
    end)
    |> Multi.update(:update_account, &account_changeset(&1, account, attrs))
    |> Repo.transaction()
    |> as_result()
  end

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
