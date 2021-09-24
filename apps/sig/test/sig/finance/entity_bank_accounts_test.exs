defmodule Sig.Finance.Banks.EntityBankAccountsTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "list_by_entity/1" do
    test "lists EntityBankAccount by entity" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      %{bank_account_id: account_id_1} = insert(:entity_bank_account, org: org, entity: entity)
      %{bank_account_id: account_id_2} = insert(:entity_bank_account, org: org, entity: entity)

      _to_ignore_1 = insert(:entity_bank_account, org: org)
      _to_ignore_2 = insert(:entity_bank_account)

      assert [
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_1
               },
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_2
               }
             ] = EntityBankAccounts.list_by_entity(entity)
    end

    test "entity has no EntityBankAccount" do
      entity = insert(:entity)

      assert EntityBankAccounts.list_by_entity(entity) == []
    end
  end

  describe "list_by_entity_with_account/1" do
    test "lists EntityBankAccount by entity ordered by inserted_at preloaded with Account" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      %{bank_account_id: account_id_1} = insert(:entity_bank_account, org: org, entity: entity)
      %{bank_account_id: account_id_2} = insert(:entity_bank_account, org: org, entity: entity)

      _to_ignore_1 = insert(:entity_bank_account, org: org)
      _to_ignore_2 = insert(:entity_bank_account)

      assert [
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_1,
                 bank_account: %Account{}
               },
               %EntityBankAccount{
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 bank_account_id: ^account_id_2,
                 bank_account: %Account{}
               }
             ] = EntityBankAccounts.list_by_entity_with_account(entity)
    end

    test "entity has no EntityBankAccount" do
      entity = insert(:entity)

      assert EntityBankAccounts.list_by_entity_with_account(entity) == []
    end
  end

  describe "fetch_entity_primary/1" do
    test "gets the entity primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      %{bank_account_id: primary_eba_account_id} =
        insert(:entity_bank_account, org: org, entity: entity, is_primary: true)

      insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert {:ok, %EntityBankAccount{bank_account_id: ^primary_eba_account_id}} =
               EntityBankAccounts.fetch_entity_primary(entity)
    end

    test "when entity doesn't have a primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert EntityBankAccounts.fetch_entity_primary(entity) == {:error, :not_found}
    end

    test "when entity doesn't have any EntityBankAccount" do
      entity = insert(:entity)

      assert EntityBankAccounts.fetch_entity_primary(entity) == {:error, :not_found}
    end
  end
end
