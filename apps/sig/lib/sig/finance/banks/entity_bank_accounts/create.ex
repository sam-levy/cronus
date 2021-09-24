defmodule Sig.Finance.Banks.EntityBankAccounts.Create do
  alias Ecto.Multi

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.BackUpdater, as: AccountsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.BackUpdater, as: EBAsBackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  def call(%Entity{} = entity, %{} = attrs) do
    Multi.new()
    |> Multi.run(:account, fn _, _ -> fetch_account_and_validate(entity, attrs) end)
    |> Multi.run(:validate_relationship, &validate_relationship(&1, &2, entity, attrs))
    |> Multi.run(:existing_primary_account, fn _, _ ->
      AccountsBackUpdater.handle_existing_primary_account(entity, attrs)
    end)
    |> Multi.run(:existing_primary_eba, fn _, _ ->
      EBAsBackUpdater.handle_existing_primary_eba(entity, attrs)
    end)
    |> Multi.insert(:create_eba, &eba_changeset(&1, entity, attrs))
    |> Repo.transaction()
    |> as_result()
  end

  defp fetch_account_and_validate(%{id: entity_id} = entity, attrs) do
    %{org: org} = Repo.preload(entity, :org)

    case Accounts.fetch_in_org_with_entity(org, attrs.bank_account_id) do
      {:error, :not_found} ->
        {:error, "account doesn't exist"}

      {:ok, %{is_active: false}} ->
        {:error, "inactive account"}

      {:ok, %{is_active: true, entity_id: ^entity_id}} ->
        {:error, "account belongs to entity"}

      {:ok, %{is_active: true, is_joint_account: false}} when attrs.is_joint_account_holder ->
        {:error, "not a joint account"}

      {:ok, %{is_active: true} = account} ->
        {:ok, account}
    end
  end

  defp validate_relationship(
         _,
         %{account: %{entity: %{type: :individual}} = _account},
         %{type: :individual} = _entity,
         attrs
       ) do
    if attrs.relationship_with_holder in EntityBankAccount.individuals_relationships() do
      {:ok, true}
    else
      {:error, "invalid relationship with holder"}
    end
  end

  defp validate_relationship(
         _,
         %{account: %{entity: %{type: :individual}} = _account},
         %{type: :company} = _entity,
         attrs
       ) do
    if attrs.relationship_with_holder in EntityBankAccount.individual_company_relationships() do
      {:ok, true}
    else
      {:error, "invalid relationship with holder"}
    end
  end

  defp validate_relationship(
         _,
         %{account: %{entity: %{type: :company}} = _account},
         %{type: :individual} = _entity,
         attrs
       ) do
    if attrs.relationship_with_holder in EntityBankAccount.individual_company_relationships() do
      {:ok, true}
    else
      {:error, "invalid relationship with holder"}
    end
  end

  defp validate_relationship(
         _,
         %{account: %{entity: %{type: :company}} = _account},
         %{type: :company} = _entity,
         attrs
       ) do
    if attrs.relationship_with_holder in EntityBankAccount.companies_relationships() do
      {:ok, true}
    else
      {:error, "invalid relationship with holder"}
    end
  end

  defp eba_changeset(
         %{existing_primary_account: nil, existing_primary_eba: nil, account: account},
         entity,
         attrs
       ) do
    attrs
    |> assign_keys(entity, account)
    |> Map.put(:is_primary, true)
    |> EntityBankAccount.create_changeset()
  end

  defp eba_changeset(%{account: account}, entity, attrs) do
    attrs
    |> assign_keys(entity, account)
    |> EntityBankAccount.create_changeset()
  end

  defp assign_keys(attrs, entity, account) do
    attrs
    |> Map.put(:org_id, entity.org_id)
    |> Map.put(:entity_id, entity.id)
    |> Map.put(:bank_account_id, account.id)
  end

  defp as_result({:ok, %{create_eba: eba}}), do: {:ok, eba}
  defp as_result({:error, _operation, reason, _changes}), do: {:error, reason}
end
