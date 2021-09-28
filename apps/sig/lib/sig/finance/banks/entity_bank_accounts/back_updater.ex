defmodule Sig.Finance.Banks.EntityBankAccounts.BackUpdater do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def handle_existing_primary_eba(
        %Entity{} = entity,
        %{} = attrs,
        eba_to_update \\ nil
      ) do
    entity
    |> EntityBankAccounts.fetch_entity_primary()
    |> maybe_set_is_primary_false(eba_to_update, attrs)
  end

  defp maybe_set_is_primary_false({:error, :not_found}, _eba_to_update, _attrs) do
    {:ok, nil}
  end

  defp maybe_set_is_primary_false(
         {:ok,
          %EntityBankAccount{
            org_id: org_id,
            entity_id: entity_id,
            bank_account_id: bank_account_id
          } = existing_primary_eba},
         %EntityBankAccount{
           org_id: org_id,
           entity_id: entity_id,
           bank_account_id: bank_account_id
         } = _eba_to_update,
         _attrs
       ) do
    {:ok, existing_primary_eba}
  end

  defp maybe_set_is_primary_false(
         {:ok, existing_primary_eba},
         _eba_to_update,
         %{is_primary: true} = _attrs
       ) do
    do_set_is_primary_false(existing_primary_eba)
  end

  defp maybe_set_is_primary_false(
         {:ok, existing_primary_eba},
         _eba_to_update,
         _attrs
       ) do
    {:ok, existing_primary_eba}
  end

  defp do_set_is_primary_false(existing_primary_eba) do
    existing_primary_eba
    |> EntityBankAccount.is_primary_false_changeset()
    |> Repo.update()
  end
end
