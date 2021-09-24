defmodule Sig.Finance.Banks.EntityBankAccounts.UpdateTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts.Update
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "call/3" do
    test "updates a bank account" do
      eba = insert(:entity_bank_account, is_primary: false)

      attrs = %{is_primary: true}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      assert Repo.get_by(EntityBankAccount,
               org_id: eba.org_id,
               entity_id: eba.entity_id,
               bank_account_id: eba.bank_account_id,
               is_primary: true
             )
    end

    test "only updates allowed fields" do
      eba = insert(:entity_bank_account, is_primary: false)

      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      assert updated_eba =
               Repo.get_by(EntityBankAccount,
                 org_id: eba.org_id,
                 entity_id: eba.entity_id,
                 bank_account_id: eba.bank_account_id,
                 is_primary: true
               )

      assert updated_eba.is_joint_account_holder == eba.is_joint_account_holder
      assert updated_eba.relationship_with_holder == eba.relationship_with_holder
    end

    test "sets existing primary account is_primary to false" do
      %{org: org, entity: entity} = primary_account = insert(:bank_account, is_primary: true)

      eba = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      attrs = %{is_primary: true}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: eba.bank_account_id,
               is_primary: true
             )

      # Asserts existing primary account is_primary field was switched to false
      assert Repo.get_by(Account,
               id: primary_account.id,
               org_id: org.id,
               entity_id: entity.id,
               is_primary: false
             )
    end

    test "sets existing primary EntityBankAccount is_primary to false" do
      %{org: org, entity: entity} = primary_eba = insert(:entity_bank_account, is_primary: true)

      eba = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      attrs = %{is_primary: true}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: eba.bank_account_id,
               is_primary: true
             )

      # Asserts existing primary EntityBankAccount is_primary field was switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: primary_eba.bank_account_id,
               is_primary: false
             )
    end

    test "doesn't set existing primary account is_primary field to false when is not primary" do
      %{org: org, entity: entity} = primary_account = insert(:bank_account, is_primary: true)

      eba = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      attrs = %{is_primary: false}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: eba.bank_account_id,
               is_primary: false
             )

      # Asserts existing primary account is_primary field was NOT switched to false
      assert Repo.get_by(Account,
               id: primary_account.id,
               org_id: org.id,
               entity_id: entity.id,
               is_primary: true
             )
    end

    test "doesn't set existing primary EntityBankAccount is_primary field to false when is not primary" do
      %{org: org, entity: entity} = primary_eba = insert(:entity_bank_account, is_primary: true)

      eba = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      attrs = %{is_primary: false}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: eba.bank_account_id,
               is_primary: false
             )

      # Asserts existing EntityBankAccount is_primary field was NOT switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: primary_eba.bank_account_id,
               is_primary: true
             )
    end

    test "sets itself is_primary to true when entity has no primary accounts or primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      existing_account = insert(:bank_account, is_primary: false, org: org, entity: entity)
      existing_eba = insert(:entity_bank_account, is_primary: false, org: org, entity: entity)

      eba = insert(:entity_bank_account, org: org, entity: entity, is_primary: false)

      attrs = %{is_primary: false}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: eba.bank_account_id,
               is_primary: true
             )

      # Asserts existing account is_primary field remains false
      assert Repo.get_by(Account,
               id: existing_account.id,
               org_id: org.id,
               entity_id: entity.id,
               is_primary: false
             )

      # Asserts existing EntityBankAccount is_primary field remains false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: existing_eba.bank_account_id,
               is_primary: false
             )
    end

    test "sets itself is_primary to true when entity has no accounts or EntityBankAccount" do
      eba = insert(:entity_bank_account, is_primary: false)

      attrs = %{is_primary: false}

      assert {:ok, %EntityBankAccount{}} = Update.call(eba, attrs)

      # Asserts EntityBankAccount was updated
      assert Repo.get_by(EntityBankAccount,
               org_id: eba.org_id,
               entity_id: eba.entity_id,
               bank_account_id: eba.bank_account_id,
               is_primary: true
             )
    end
  end
end
