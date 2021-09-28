defmodule Sig.Finance.Banks.Accounts.BackUpdater do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Repo

  def handle_existing_primary_account(
        %Entity{} = entity,
        %{} = attrs,
        account_to_update \\ nil
      ) do
    entity
    |> Accounts.fetch_entity_primary()
    |> maybe_set_is_primary_false(account_to_update, attrs)
  end

  defp maybe_set_is_primary_false({:error, :not_found}, _account_to_update, _attrs) do
    {:ok, nil}
  end

  defp maybe_set_is_primary_false(
         {:ok, %Account{id: id} = existing_primary_account},
         %Account{id: id} = _account_to_update,
         _attrs
       ) do
    {:ok, existing_primary_account}
  end

  defp maybe_set_is_primary_false(
         {:ok, existing_primary_account},
         _account_to_update,
         %{is_primary: true} = _attrs
       ) do
    do_set_is_primary_false(existing_primary_account)
  end

  defp maybe_set_is_primary_false(
         {:ok, existing_primary_account},
         _account_to_update,
         _attrs
       ) do
    {:ok, existing_primary_account}
  end

  defp do_set_is_primary_false(existing_primary_account) do
    existing_primary_account
    |> Account.is_primary_false_changeset()
    |> Repo.update()
  end
end
