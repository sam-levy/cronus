defmodule Sig.Finance.Banks.Accounts.BackUpdater do
  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Repo

  @doc ~S"""
  Sets the `is_primary` field of the existing primary %Account{} to false if
  one exists. NOOP if there is no primary bank account or no bank account at all.
  Returns the updated bank account if one exists. Returns nil if there is no
  primary bank account.
  """

  def maybe_set_existing_primary_account_to_false(%Entity{} = entity, %{} = attrs) do
    Multi.new()
    |> Multi.run(:existing_primary_account, fn _, _ ->
      {:ok, Accounts.get_entity_primary(entity)}
    end)
    |> Multi.merge(&update_existing_account(&1, attrs))
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

  defp as_result({:ok, %{update_existing_account: account}}), do: {:ok, account}
  defp as_result({:ok, %{existing_primary_account: account}}), do: {:ok, account}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
