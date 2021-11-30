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
end
