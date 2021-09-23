defmodule Sig.Finance.Banks.EntityBankAccounts.BackUpdater do
  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  @doc ~S"""
  Sets the `is_primary` field of the existing primary %EntityBankAccount{}
  to false if one exists. NOOP if there is no primary %EntityBankAccount{}
  or no %EntityBankAccount{} at all. Returns the updated %EntityBankAccount{}
  if one exists. Returns nil if there is no %EntityBankAccount{}.
  """

  def maybe_set_existing_primary_eba_to_false(%Entity{} = entity, %{} = attrs) do
    Multi.new()
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      {:ok, EntityBankAccounts.get_entity_primary(entity)}
    end)
    |> Multi.merge(&update_existing_eba(&1, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp update_existing_eba(%{existing_primary_eba: nil}, _attrs), do: Multi.new()

  defp update_existing_eba(
         %{existing_primary_eba: existing_primary_eba},
         %{is_primary: true} = _attrs
       ) do
    changeset = EntityBankAccount.update_changeset(existing_primary_eba, %{is_primary: false})

    Multi.update(Multi.new(), :update_existing_eba, changeset)
  end

  defp update_existing_eba(_changes, _attrs), do: Multi.new()

  defp as_result({:ok, %{update_existing_eba: eba}}), do: {:ok, eba}
  defp as_result({:ok, %{existing_primary_eba: eba}}), do: {:ok, eba}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
