defmodule Sig.Finance.Banks.Accounts.UpdateTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.Update
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "call/3" do
    test "updates a bank account" do
      account =
        insert(:bank_account,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: true
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: account.id,
                 org_id: account.org_id,
                 entity_id: account.entity_id
               })
             )
    end

    test "only updates allowed fields" do
      account =
        insert(:bank_account,
          type: random_enum_value(:bank_account_type),
          routing_number: random_bank_routing_number(),
          branch_number: random_string_number(),
          number: random_string_number(),
          other_info: %{"OP" => "001"},
          is_joint_account: false,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: true
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      assert updated_account =
               Repo.get_by(
                 Account,
                 Enum.into(attrs, %{
                  id: account.id,
                  org_id: account.org_id,
                  entity_id: account.entity_id
                 })
               )

      assert updated_account.type == account.type
      assert updated_account.routing_number == account.routing_number
      assert updated_account.branch_number == account.branch_number
      assert updated_account.number == account.number
      assert updated_account.other_info == account.other_info
      assert updated_account.is_joint_account == account.is_joint_account
    end

    test "invalid attrs" do
      account = insert(:bank_account, is_primary: true)

      attrs = %{
        pix_key: :invalid,
        is_active: :invalid,
        is_primary: :invalid
      }

      assert {:error, changeset} = Update.call(account, attrs)

      assert %Account{} = changeset.data

      assert errors_on(changeset) == %{
               is_active: ["is invalid"],
               is_primary: ["is invalid"],
               pix_key: ["is invalid"]
             }
    end

    test "sets existing primary account is_primary to false" do
      %{org: org, entity: entity} = primary_account = insert(:bank_account, is_primary: true)

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: true
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      # Asserts account was updated
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: account.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
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

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: true
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      # Asserts account was updated
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: account.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
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

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: false
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      # Asserts account was updated
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: account.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
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

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: false
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      # Asserts account was updated
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: account.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
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

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: false
      }

      assert {:ok, %Account{}} = Update.call(account, attrs)

      # Asserts account was updated with is_primary switched to true
      assert Repo.get_by(Account,
               id: account.id,
               org_id: org.id,
               entity_id: entity.id,
               pix_key: "new_pix_key",
               is_active: true,
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
      entity = insert(:entity)

      account =
        insert(:bank_account,
          org: entity.org,
          entity: entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: false
      }

      assert {:ok, %Account{} = return} = Update.call(account, attrs)

      # Asserts new account was inserted with is_primary switched to true
      assert Repo.get_by(Account,
               id: return.id,
               org_id: entity.org_id,
               entity_id: entity.id,
               is_primary: true
             )
    end
  end
end
