defmodule Sig.Finance.Banks.EntityBankAccountsTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "list_by_entity_with_account/2" do
    test "lists EntityBankAccount by entity ordered by inserted_at preloaded with Account" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      %{bank_account_id: account_id_1} =
        insert(:entity_bank_account, org: org, entity: entity)

      %{bank_account_id: account_id_2} =
        insert(:entity_bank_account, org: org, entity: entity)

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
             ] = EntityBankAccounts.list_by_entity_with_account(org.id, entity.id)
    end

    test "entity has no EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      assert EntityBankAccounts.list_by_entity_with_account(org.id, entity.id) == []
    end
  end
end
