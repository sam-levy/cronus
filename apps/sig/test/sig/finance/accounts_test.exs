defmodule Sig.Finance.Banks.AccountsTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account

  describe "list_by_entity/1" do
    test "lists bank accounts by entity ordered by inserted_at" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      %{id: id_1} = insert(:bank_account, org: org, entity: entity)
      %{id: id_2} = insert(:bank_account, org: org, entity: entity)

      _to_ignore_1 = insert(:bank_account, org: org)
      _to_ignore_2 = insert(:bank_account)

      assert [
               %Account{
                 id: ^id_1,
                 org_id: ^org_id,
                 entity_id: ^entity_id
               },
               %Account{
                 id: ^id_2,
                 org_id: ^org_id,
                 entity_id: ^entity_id
               }
             ] = Accounts.list_by_entity(entity)
    end

    test "entity has no bank account" do
      entity = insert(:entity)

      assert Accounts.list_by_entity(entity) == []
    end
  end

  describe "get_entity_primary/1" do
    test "gets the entity primary account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      %{id: primary_account_id} =
        insert(:bank_account, org: org, entity: entity, is_primary: true)

      insert(:bank_account, org: org, entity: entity, is_primary: false)

      assert %Account{id: ^primary_account_id} = Accounts.get_entity_primary(entity)
    end

    test "when entity doesn't have a primary account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:bank_account, org: org, entity: entity, is_primary: false)

      assert Accounts.get_entity_primary(entity) == nil
    end

    test "when entity doesn't have any account" do
      entity = insert(:entity)

      assert Accounts.get_entity_primary(entity) == nil
    end
  end
end
