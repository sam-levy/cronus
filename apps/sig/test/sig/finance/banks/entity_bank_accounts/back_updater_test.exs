defmodule Sig.Finance.Banks.EntityBankAccounts.BackUpdaterTest do
  use Sig.DataCase, async: true

  alias Sig.Finance.Banks.EntityBankAccounts.BackUpdater
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "handle_existing_primary_eba/3" do
    test "no existing primary EntityBankAccount" do
      entity = insert(:entity)

      existing_account =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: false)

      assert BackUpdater.handle_existing_primary_eba(entity, %{is_primary: true}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_eba(entity, %{is_primary: false}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_eba(entity, %{other_attr: "value"}) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_eba(
               entity,
               %{is_primary: true},
               existing_account
             ) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_eba(
               entity,
               %{is_primary: false},
               existing_account
             ) ==
               {:ok, nil}

      assert BackUpdater.handle_existing_primary_eba(
               entity,
               %{other_attr: "value"},
               existing_account
             ) ==
               {:ok, nil}
    end

    test "doesn't update when the EntityBankAccount being updated IS the existing primary EntityBankAccount" do
      entity = insert(:entity)

      existing_primary_eba =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: true)

      assert {:ok, %EntityBankAccount{is_primary: true}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{is_primary: false},
                 existing_primary_eba
               )
    end

    test "Set the existing primary EntityBankAccount to false when the EntityBankAccount being updated is NOT the existing primary one." do
      entity = insert(:entity)

      existing_primary_eba =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: true)

      eba = insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: false)

      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{is_primary: true},
                 eba
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: false
             )
    end

    test "Set the existing primary account to false when it's an insertion of a primary account" do
      entity = insert(:entity)

      existing_primary_eba =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: true)

      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(entity, %{is_primary: true})

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: false
             )
    end

    test "attrs is_primary false" do
      entity = insert(:entity)

      existing_primary_eba =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: true)

      eba = insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: false)

      # Updating the existing primary EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{is_primary: false},
                 existing_primary_eba
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )

      # Updating another EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{is_primary: false},
                 eba
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )

      # Inserting new EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{is_primary: false}
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )
    end

    test "attrs without is_primary key" do
      entity = insert(:entity)

      existing_primary_eba =
        insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: true)

      eba = insert(:entity_bank_account, org: entity.org, entity: entity, is_primary: false)

      # Updating the existing primary EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{other_attr: "value"},
                 existing_primary_eba
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )

      # Updating another EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{other_attr: "value"},
                 eba
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )

      # Inserting new EntityBankAccount
      assert {:ok, %EntityBankAccount{}} =
               BackUpdater.handle_existing_primary_eba(
                 entity,
                 %{other_attr: "value"}
               )

      assert Repo.get_by(EntityBankAccount,
               org_id: existing_primary_eba.org_id,
               entity_id: existing_primary_eba.entity_id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )
    end
  end
end
