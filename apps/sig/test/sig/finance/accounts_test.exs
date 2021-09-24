defmodule Sig.Finance.Banks.AccountsTest do
  use Sig.DataCase

  alias Sig.Entities.Entity
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

  describe "list_active_by_entity/1" do
    test "lists active bank accounts by entity ordered by inserted_at" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      %{id: id_1} = insert(:bank_account, org: org, entity: entity, is_active: true)
      %{id: id_2} = insert(:bank_account, org: org, entity: entity, is_active: true)

      _to_ignore_1 = insert(:bank_account, org: org, entity: entity, is_active: false)
      _to_ignore_2 = insert(:bank_account, org: org, is_active: true)
      _to_ignore_3 = insert(:bank_account, is_active: true)

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
             ] = Accounts.list_active_by_entity(entity)
    end

    test "entity has no active bank account" do
      %{entity: entity} = insert(:bank_account, is_active: false)

      assert Accounts.list_active_by_entity(entity) == []
    end
  end

  describe "fetch_entity_primary/1" do
    test "fetches the entity primary account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      %{id: primary_account_id} =
        insert(:bank_account, org: org, entity: entity, is_primary: true)

      insert(:bank_account, org: org, entity: entity, is_primary: false)

      assert {:ok, %Account{id: ^primary_account_id}} = Accounts.fetch_entity_primary(entity)
    end

    test "when entity doesn't have a primary account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:bank_account, org: org, entity: entity, is_primary: false)

      assert Accounts.fetch_entity_primary(entity) == {:error, :not_found}
    end

    test "when entity doesn't have any account" do
      entity = insert(:entity)

      assert Accounts.fetch_entity_primary(entity) == {:error, :not_found}
    end
  end

  describe "fetch_in_org_with_entity/2" do
    test "fetches a bank account from an org preloaded with the entity" do
      %{id: id, org: org, org_id: org_id} = insert(:bank_account)

      assert {:ok, %Account{id: ^id, org_id: ^org_id, entity: %Entity{}}} =
               Accounts.fetch_in_org_with_entity(org, id)
    end

    test "when bank account belongs to another org" do
      %{id: id} = insert(:bank_account)
      another_org = insert(:org)

      assert Accounts.fetch_in_org_with_entity(another_org, id) == {:error, :not_found}
    end

    test "when bank account doesn't exist" do
      org = insert(:org)

      assert Accounts.fetch_in_org_with_entity(org, UUID.generate()) == {:error, :not_found}
    end
  end
end
