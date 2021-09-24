defmodule Sig.Finance.Banks.EntityBankAccounts.CreateTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts.Create
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "call/3" do
    test "creates an EntityBankAccount" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: entity_2.id,
                 bank_account_id: entity_1_account.id
               })
             )
    end

    test "invalid attrs" do
      org = insert(:org)
      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)

      attrs = %{
        bank_account_id: entity_1_account.id,
        relationship_with_holder: :partner,
        is_joint_account_holder: :invalid
      }

      assert {:error, changeset} = Create.call(entity_2, attrs)

      assert errors_on(changeset) == %{
               is_joint_account_holder: ["is invalid"]
             }
    end

    test "sets existing primary account is_primary to false" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)
      entity_2_account = insert(:bank_account, org: org, entity: entity_2, is_primary: true)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new eba was inserted
      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: entity_2.id,
                 bank_account_id: entity_1_account.id
               })
             )

      # Asserts existing primary account is_primary field was switched to false
      assert Repo.get_by(Account,
               id: entity_2_account.id,
               org_id: org.id,
               entity_id: entity_2.id,
               is_primary: false
             )
    end

    test "sets existing primary EntityBankAccount is_primary to false" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :legal)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)

      entity_2_existing_primary_eba =
        insert(:entity_bank_account, org: org, entity: entity_2, is_primary: true)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :company_owner
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new eba was inserted
      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: entity_2.id,
                 bank_account_id: entity_1_account.id
               })
             )

      # Asserts existing primary EntityBankAccount is_primary field was switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity_2.id,
               bank_account_id: entity_2_existing_primary_eba.bank_account_id,
               is_primary: false
             )
    end

    test "doesn't set existing primary account is_primary field to false when is not primary" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :legal)
      entity_2 = insert(:entity, org: org, type: :legal)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)
      entity_2_account = insert(:bank_account, org: org, entity: entity_2, is_primary: true)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :same_owner_company
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new eba was inserted
      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: entity_2.id,
                 bank_account_id: entity_1_account.id
               })
             )

      # Asserts existing primary account is_primary field was NOT switched to false
      assert Repo.get_by(Account,
               id: entity_2_account.id,
               org_id: org.id,
               entity_id: entity_2.id,
               is_primary: true
             )
    end

    test "doesn't set existing primary eba is_primary field to false when is not primary" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)

      entity_2_existing_primary_eba =
        insert(:entity_bank_account, org: org, entity: entity_2, is_primary: true)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new eba was inserted
      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: entity_2.id,
                 bank_account_id: entity_1_account.id
               })
             )

      # Asserts existing primary EntityBankAccount is_primary field was NOT switched to false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity_2.id,
               bank_account_id: entity_2_existing_primary_eba.bank_account_id,
               is_primary: true
             )
    end

    test "sets itself is_primary to true when entity has no primary accounts or primary EntityBankAccount" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account_1 = insert(:bank_account, org: org, entity: entity_1)
      entity_1_account_2 = insert(:bank_account, org: org, entity: entity_1)

      entity_2_existing_eba =
        insert(:entity_bank_account,
          org: org,
          entity: entity_2,
          bank_account: entity_1_account_1,
          is_primary: false
        )

      entity_2_existing_account =
        insert(:bank_account, org: org, entity: entity_2, is_primary: false)

      attrs = %{
        bank_account_id: entity_1_account_2.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new EntityBankAccount was inserted with is_primary switched to true
      assert Repo.get_by(EntityBankAccount,
               org_id: entity_2.org_id,
               entity_id: entity_2.id,
               bank_account_id: entity_1_account_2.id,
               is_primary: true
             )

      # Asserts existing account is_primary field remains false
      assert Repo.get_by(Account,
               id: entity_2_existing_account.id,
               org_id: org.id,
               entity_id: entity_2.id,
               is_primary: false
             )

      # Asserts existing EntityBankAccount is_primary field remains false
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity_2.id,
               bank_account_id: entity_2_existing_eba.bank_account_id,
               is_primary: false
             )
    end

    test "sets itself is_primary to true when entity has no accounts or EntityBankAccount" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :partner
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(entity_2, attrs)

      # Asserts new EntityBankAccount was inserted with is_primary switched to true
      assert Repo.get_by(EntityBankAccount,
               org_id: org.id,
               entity_id: entity_2.id,
               bank_account_id: entity_1_account.id,
               is_primary: true
             )
    end

    test "account doesn't exist" do
      entity = insert(:entity)

      attrs = %{
        bank_account_id: UUID.generate(),
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :partner
      }

      assert {:error, "account doesn't exist"} = Create.call(entity, attrs)
    end

    test "inactive account" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1, is_active: false)

      attrs = %{
        bank_account_id: entity_1_account.id,
        relationship_with_holder: :child
      }

      assert Create.call(entity_2, attrs) == {:error, "inactive account"}
    end

    test "account belongs to the same entity" do
      entity = insert(:entity, type: :individual)
      account = insert(:bank_account, org: entity.org, entity: entity)

      attrs = %{
        bank_account_id: account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert Create.call(entity, attrs) == {:error, "account belongs to entity"}
    end

    test "account belongs to another org" do
      another_org = insert(:org)

      another_org_entity = insert(:entity, org: another_org, type: :individual)
      another_org_account = insert(:bank_account, org: another_org, entity: another_org_entity)

      entity = insert(:entity, type: :individual)

      attrs = %{
        bank_account_id: another_org_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert Create.call(entity, attrs) == {:error, "account doesn't exist"}
    end

    test "account is_joint_account is false and attrs is_joint_account_holder is true" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org, type: :individual)
      entity_2 = insert(:entity, org: org, type: :individual)

      entity_1_account =
        insert(:bank_account, org: org, entity: entity_1, is_joint_account: false)

      attrs = %{
        bank_account_id: entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: true,
        relationship_with_holder: :partner
      }

      assert Create.call(entity_2, attrs) == {:error, "not a joint account"}
    end

    test "invalid relationship when legal to individual" do
      org = insert(:org)

      company_entity = insert(:entity, org: org, type: :legal)
      individual_entity = insert(:entity, org: org, type: :individual)

      company_entity_account = insert(:bank_account, org: org, entity: company_entity)

      attrs = %{
        bank_account_id: company_entity_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :partner
      }

      assert Create.call(individual_entity, attrs) == {:error, "invalid relationship with holder"}
    end

    test "valid relationship when legal to individual" do
      org = insert(:org)

      company_entity = insert(:entity, org: org, type: :legal)
      individual_entity = insert(:entity, org: org, type: :individual)

      company_entity_account = insert(:bank_account, org: org, entity: company_entity)

      attrs = %{
        bank_account_id: company_entity_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :company_owner
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(individual_entity, attrs)

      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: individual_entity.id,
                 bank_account_id: company_entity_account.id
               })
             )
    end

    test "invalid relationship when individual to legal" do
      org = insert(:org)

      individual_entity = insert(:entity, org: org, type: :individual)
      company_entity = insert(:entity, org: org, type: :legal)

      individual_entity_account = insert(:bank_account, org: org, entity: individual_entity)

      attrs = %{
        bank_account_id: individual_entity_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert Create.call(company_entity, attrs) == {:error, "invalid relationship with holder"}
    end

    test "valid relationship when individual to legal" do
      org = insert(:org)

      individual_entity = insert(:entity, org: org, type: :individual)
      company_entity = insert(:entity, org: org, type: :legal)

      individual_entity_account = insert(:bank_account, org: org, entity: individual_entity)

      attrs = %{
        bank_account_id: individual_entity_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :company_owner
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(company_entity, attrs)

      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: company_entity.id,
                 bank_account_id: individual_entity_account.id
               })
             )
    end

    test "invalid relationship when legal to legal" do
      org = insert(:org)

      company_entity_1 = insert(:entity, org: org, type: :legal)
      company_entity_2 = insert(:entity, org: org, type: :legal)

      company_entity_1_account = insert(:bank_account, org: org, entity: company_entity_1)

      attrs = %{
        bank_account_id: company_entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :company_owner
      }

      assert Create.call(company_entity_2, attrs) == {:error, "invalid relationship with holder"}
    end

    test "valid relationship when legal to legal" do
      org = insert(:org)

      company_entity_1 = insert(:entity, org: org, type: :legal)
      company_entity_2 = insert(:entity, org: org, type: :legal)

      company_entity_1_account = insert(:bank_account, org: org, entity: company_entity_1)

      attrs = %{
        bank_account_id: company_entity_1_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :same_owner_company
      }

      assert {:ok, %EntityBankAccount{}} = Create.call(company_entity_2, attrs)

      assert Repo.get_by(
               EntityBankAccount,
               Enum.into(attrs, %{
                 org_id: org.id,
                 entity_id: company_entity_2.id,
                 bank_account_id: company_entity_1_account.id
               })
             )
    end

    test "invalid relationship when individual to individual" do
      org = insert(:org)

      individual_entity_1 = insert(:entity, org: org, type: :individual)
      individual_entity_2 = insert(:entity, org: org, type: :individual)

      individual_entity_1_account = insert(:bank_account, org: org, entity: individual_entity_1)

      attrs = %{
        bank_account_id: individual_entity_1_account.id,
        is_primary: false,
        is_joint_account_holder: false,
        relationship_with_holder: :same_owner_company
      }

      assert Create.call(individual_entity_2, attrs) ==
               {:error, "invalid relationship with holder"}
    end
  end
end
