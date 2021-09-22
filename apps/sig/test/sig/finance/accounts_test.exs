defmodule Sig.Finance.Banks.EntityBankAccountsTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account

  describe "list_by_entity/2" do
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
                 entity_id: ^entity_id,
               },
               %Account{
                 id: ^id_2,
                 org_id: ^org_id,
                 entity_id: ^entity_id,
               }
             ] = Accounts.list_by_entity(org.id, entity.id)
    end

    test "entity has no bank account" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      assert Accounts.list_by_entity(org.id, entity.id) == []
    end
  end
end
