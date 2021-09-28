defmodule Sig.Finance.Banks.EntityBankAccounts.Update do
  alias Ecto.Multi

  alias Sig.Finance.Banks.Accounts.BackUpdater, as: AccountsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.BackUpdater, as: EBAsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def call(%EntityBankAccount{} = eba, %{} = attrs) do
    %{entity: entity} = Repo.preload(eba, :entity)

    Multi.new()
    |> Multi.run(:existing_primary_account, fn _, _ ->
      AccountsBackUpdater.handle_existing_primary_account(entity, attrs)
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      EBAsBackUpdater.handle_existing_primary_eba(entity, attrs, eba)
    end)
    |> Multi.update(:update_eba, &eba_changeset(&1, eba, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp eba_changeset(%{existing_primary_account: nil, existing_primary_eba: nil}, eba, attrs) do
    attrs = Map.put(attrs, :is_primary, true)

    EntityBankAccount.update_changeset(eba, attrs)
  end

  defp eba_changeset(_, eba, attrs), do: EntityBankAccount.update_changeset(eba, attrs)

  defp as_result({:ok, %{update_eba: eba}}), do: {:ok, eba}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
