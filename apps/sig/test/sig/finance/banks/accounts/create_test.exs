defmodule Sig.Finance.Banks.Accounts.CreateTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.Create
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "call/3" do
    test "creates a bank account" do
      entity = insert(:entity)

      attrs = %{
        type: random_enum_value(:bank_account_type),
        routing_number: random_bank_routing_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        other_info: %{"OP" => "001"},
        pix_key: "pix_key",
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: entity.org_id,
                 entity_id: entity.id
               })
             )
    end

    test "invalid attrs" do
      entity = insert(:entity)

      assert {:error, changeset} = Create.call(entity, %{})

      assert %Account{} = changeset.data

      assert errors_on(changeset) == %{
               type: ["can't be blank"],
               routing_number: ["can't be blank"],
               branch_number: ["can't be blank"],
               number: ["can't be blank"]
             }
    end

    test "sets existing primary account is_primary to false" do
      %{org: org, entity: entity} =
        existing_primary_account = insert(:bank_account, is_primary: true)

      attrs = attrs_for(:bank_account, is_primary: true)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      # Asserts new account was inserted
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
             )

      # Asserts existing primary account is_primary field was switched to false
      assert Repo.get_by(Account,
               id: existing_primary_account.id,
               org_id: org.id,
               entity_id: entity.id,
               is_primary: false
             )
    end

    test "sets existing primary EntityBankAccount is_primary to false" do
      %{org: org, entity: entity} =
        existing_primary_eba = insert(:entity_bank_account, is_primary: true)

      attrs = attrs_for(:bank_account, is_primary: true)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      # Asserts new account was inserted
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
             )

      # Asserts existing primary EntityBankAccount is_primary field was switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: false
             )
    end

    test "doesn't set existing primary account is_primary field to false when is not primary" do
      %{org: org, entity: entity} =
        existing_primary_account = insert(:bank_account, is_primary: true)

      attrs = attrs_for(:bank_account, is_primary: false)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      # Asserts new account was inserted
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
             )

      # Asserts existing primary account is_primary field was NOT switched to false
      assert Repo.get_by(Account,
               id: existing_primary_account.id,
               org_id: org.id,
               entity_id: entity.id,
               is_primary: true
             )
    end

    test "doesn't set existing primary EntityBankAccount is_primary field to false when is not primary" do
      %{org: org, entity: entity} =
        existing_primary_eba = insert(:entity_bank_account, is_primary: true)

      attrs = attrs_for(:bank_account, is_primary: false)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      # Asserts new account was inserted
      assert Repo.get_by(
               Account,
               Enum.into(attrs, %{
                 id: return.id,
                 org_id: org.id,
                 entity_id: entity.id
               })
             )

      # Asserts existing primary EntityBankAccount is_primary field was NOT switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity.id,
               bank_account_id: existing_primary_eba.bank_account_id,
               is_primary: true
             )
    end

    test "sets itself is_primary to true when there are no primary accounts or primary EntityBankAccount" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      existing_account = insert(:bank_account, is_primary: false, org: org, entity: entity)
      existing_eba = insert(:entity_bank_account, is_primary: false, org: org, entity: entity)

      attrs = attrs_for(:bank_account, is_primary: false)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

      # Asserts new account was inserted with is_primary switched to true
      assert Repo.get_by(Account,
        id: return.id,
        org_id: entity.org_id,
        entity_id: entity.id,
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

    test "sets itself is_primary to true when there are no accounts or EntityBankAccount" do
      entity = insert(:entity)

      attrs = attrs_for(:bank_account, is_primary: false)

      assert {:ok, %Account{} = return} = Create.call(entity, attrs)

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
