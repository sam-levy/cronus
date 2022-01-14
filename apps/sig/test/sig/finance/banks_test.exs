defmodule Sig.Finance.BanksTest do
  use Sig.DataCase

  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Bank
  alias Sig.Finance.Banks.Accounts.Account

  describe "list_banks/0" do
    test "returns all banks" do
      assert [%Bank{} | _banks] = Banks.list_banks()
    end
  end

  describe "fetch_bank/1" do
    test "returns a bank" do
      assert {:ok, %Bank{name: "Banco do Brasil S.A."}} = Banks.fetch_bank("001")
    end

    test "invalid routing number" do
      assert Banks.fetch_bank("invalid") == {:error, :not_found}
    end
  end

  describe "valid_routing_number/1" do
    test "when valid" do
      assert Banks.valid_routing_number?("001")
    end

    test "when invalid" do
      refute Banks.valid_routing_number?("invalid")
    end
  end

  describe "list_active_bank_accounts_by_entity/1" do
    test "lists active accounts by entity ordered by routing number" do
      %{id: org_id} = org = insert(:org)
      %{id: entity_id} = entity = insert(:entity, org: org)

      # Accounts

      %{id: id_1} =
        insert(:bank_account, org: org, entity: entity, routing_number: "104", is_active: true)

      %{id: id_2} =
        insert(:bank_account, org: org, entity: entity, routing_number: "001", is_active: true)

      _to_ignore_1 = insert(:bank_account, org: org, entity: entity, is_active: false)
      _to_ignore_2 = insert(:bank_account, org: org, is_active: true)
      _to_ignore_3 = insert(:bank_account, is_active: true)

      # Entity Bank Accounts

      %{id: id_3, entity_id: account_3_entity_id} =
        account_3 = insert(:bank_account, org: org, routing_number: "341", is_active: true)

      insert(:entity_bank_account, org: org, entity: entity, bank_account: account_3)

      %{id: id_4, entity_id: account_4_entity_id} =
        account_4 = insert(:bank_account, org: org, routing_number: "237", is_active: true)

      insert(:entity_bank_account, org: org, entity: entity, bank_account: account_4)

      to_ignore_4 = insert(:bank_account, org: org, is_active: false)
      insert(:entity_bank_account, org: org, entity: entity, bank_account: to_ignore_4)

      _to_ignore_5 = insert(:entity_bank_account, org: org)
      _to_ignore_6 = insert(:entity_bank_account)

      assert [
               %Account{
                 id: ^id_2,
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 routing_number: "001"
               },
               %Account{
                 id: ^id_1,
                 org_id: ^org_id,
                 entity_id: ^entity_id,
                 routing_number: "104"
               },
               %Account{
                 id: ^id_4,
                 org_id: ^org_id,
                 entity_id: ^account_4_entity_id,
                 routing_number: "237"
               },
               %Account{
                 id: ^id_3,
                 org_id: ^org_id,
                 entity_id: ^account_3_entity_id,
                 routing_number: "341"
               }
             ] = Banks.list_active_bank_accounts_by_entity(entity)
    end

    test "when entity has no accounts or entity bank accounts" do
      entity = insert(:entity)

      assert Banks.list_active_bank_accounts_by_entity(entity) == []
    end
  end

  describe "fetch_entity_active_primary_bank_account/2" do
    test "fetches primary active bank account when `Account`" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      %{id: bank_account_id} =
        insert(:bank_account, org: org, entity: entity, is_active: true, is_primary: true)

      _to_ignore =
        insert(:bank_account, org: org, entity: entity, is_active: true, is_primary: false)

      _to_ignore = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert {:ok, %Account{id: ^bank_account_id}} =
               Banks.fetch_entity_active_primary_bank_account(org.id, entity.id)
    end

    test "fetches primary active bank account when `EntityBankAccount`" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      _to_ignore =
        insert(:bank_account, org: org, entity: entity, is_active: true, is_primary: false)

      %{bank_account_id: bank_account_id} =
        insert(:entity_bank_account, org: org, entity: entity, is_primary: true)

      assert {:ok, %Account{id: ^bank_account_id}} =
               Banks.fetch_entity_active_primary_bank_account(org.id, entity.id)
    end

    test "when primary bank account is not active" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:bank_account, org: org, entity: entity, is_active: false, is_primary: true)

      assert {:error, :not_found} =
               Banks.fetch_entity_active_primary_bank_account(org.id, entity.id)
    end

    test "when there is no active account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:bank_account, org: org, entity: entity, is_active: true, is_primary: false)

      insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      assert {:error, :not_found} =
               Banks.fetch_entity_active_primary_bank_account(org.id, entity.id)
    end

    test "when there is no account" do
      entity = insert(:entity)

      assert {:error, :not_found} =
               Banks.fetch_entity_active_primary_bank_account(entity.id, entity.id)
    end

    test "when entity doesn't belong to org" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:bank_account, org: org, entity: entity, is_active: true, is_primary: true)

      wrong_entity = insert(:entity)

      assert {:error, :not_found} =
               Banks.fetch_entity_active_primary_bank_account(org.id, wrong_entity.id)
    end
  end
end
