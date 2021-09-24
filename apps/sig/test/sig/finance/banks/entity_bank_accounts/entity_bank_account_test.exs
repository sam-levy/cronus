defmodule Sig.Finance.Banks.EntityBankAccounts.EntityBankAccountTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

  describe "entities_bank_accounts table constraints" do
    test "insertion" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        org_id: bank_account.org_id,
        entity_id: bank_account.entity_id,
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert {:ok, _} = Repo.insert(entity_bank_account)
    end

    test "org_id not_null_violation" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        entity_id: bank_account.entity_id,
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: true,
        relationship_with_holder: :company_owner
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "org_id foreign_key_constraint" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        org_id: UUID.generate(),
        entity_id: bank_account.entity_id,
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entity_id not_null_violation" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        org_id: bank_account.org_id,
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :partner
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "entity_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entity_id foreign_key_constraint" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        org_id: bank_account.org_id,
        entity_id: UUID.generate(),
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "bank_account_id not_null_violation" do
      entity = insert(:entity)

      entity_bank_account = %EntityBankAccount{
        org_id: entity.org_id,
        entity_id: entity.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :spouse
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "bank_account_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "bank_account_id foreign_key_constraint" do
      entity = insert(:entity)

      entity_bank_account = %EntityBankAccount{
        org_id: entity.org_id,
        entity_id: entity.id,
        bank_account_id: UUID.generate(),
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_bank_account_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entities_bank_accounts_entity_is_primary unique_constraint" do
      org = insert(:org)

      entity_1 = insert(:entity, org: org)
      entity_2 = insert(:entity, org: org)

      entity_1_account = insert(:bank_account, org: org, entity: entity_1)
      entity_2_account = insert(:bank_account, org: org, entity: entity_2)

      # Allow is_primary = true for different entities from the same org
      _entity_1_primary_eba =
        insert(:entity_bank_account,
          org: org,
          entity: entity_1,
          bank_account: entity_2_account,
          is_primary: true,
          is_joint_account_holder: false,
          relationship_with_holder: :child
        )

      _entity_2_primary_eba =
        insert(:entity_bank_account,
          org: org,
          entity: entity_2,
          bank_account: entity_1_account,
          is_primary: true,
          is_joint_account_holder: true,
          relationship_with_holder: :company_owner
        )

      entity_2_account_2 = insert(:bank_account, org: org, entity: entity_2)

      # Rises if is_primary = true for a second eba of an entity with a primary eba
      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity_1.id,
        bank_account_id: entity_2_account_2.id,
        is_primary: true,
        is_joint_account_holder: false,
        relationship_with_holder: :child
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_entity_is_primary \(unique_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "relationship_with_holder not_null_violation" do
      bank_account = insert(:bank_account)

      entity_bank_account = %EntityBankAccount{
        org_id: bank_account.org_id,
        entity_id: bank_account.entity_id,
        bank_account_id: bank_account.id,
        is_primary: true,
        is_joint_account_holder: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "relationship_with_holder\" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_primary: true,
        is_joint_account_holder: true,
        relationship_with_holder: :company_owner
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               entity_id: attrs[:entity_id],
               bank_account_id: attrs[:bank_account_id],
               is_primary: attrs[:is_primary],
               is_joint_account_holder: attrs[:is_joint_account_holder],
               relationship_with_holder: attrs[:relationship_with_holder]
             }
    end

    test "missing required attrs" do
      assert changeset = EntityBankAccount.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               entity_id: ["can't be blank"],
               bank_account_id: ["can't be blank"],
               relationship_with_holder: ["can't be blank"],
               is_joint_account_holder: ["can't be blank"],
               is_primary: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        entity_id: :invalid,
        bank_account_id: :invalid,
        is_primary: :invalid,
        is_joint_account_holder: :invalid,
        relationship_with_holder: :invalid
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               entity_id: ["is invalid"],
               bank_account_id: ["is invalid"],
               is_primary: ["is invalid"],
               is_joint_account_holder: ["is invalid"],
               relationship_with_holder: ["is invalid"]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      entity_bank_account = insert(:entity_bank_account, is_primary: false)

      attrs = %{is_primary: true}

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      assert changeset.valid?
      assert changeset.changes == %{is_primary: attrs[:is_primary]}
    end

    test "invalid attrs types" do
      entity_bank_account = insert(:entity_bank_account)

      attrs = %{is_primary: :invalid}

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{is_primary: ["is invalid"]}
    end

    test "ignores non permitted attrs" do
      entity_bank_account = insert(:entity_bank_account, is_primary: false)

      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_primary: true,
        is_joint_account_holder: true,
        relationship_with_holder: :spouse
      }

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      assert changeset.valid?
      assert changeset.changes == %{is_primary: attrs[:is_primary]}
    end
  end
end
