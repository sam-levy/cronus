defmodule Sig.Finance.Banks.EntityBankAccounts.EntityBankAccountTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount.RelationshipWithHolder

  describe "entities_bank_accounts table constraints" do
    test "insertion" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id,
        bank_account_id: bank_account.id
      }

      assert {:ok, _} = Repo.insert(entity_bank_account)
    end

    test "org_id not_null_violation" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        entity_id: entity.id,
        bank_account_id: bank_account.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "org_id foreign_key_constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: UUID.generate(),
        entity_id: entity.id,
        bank_account_id: bank_account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entity_id not_null_violation" do
      org = insert(:org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        bank_account_id: bank_account.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "entity_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entity_id foreign_key_constraint" do
      org = insert(:org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: UUID.generate(),
        bank_account_id: bank_account.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "bank_account_id not_null_violation" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "bank_account_id" of relation "entities_bank_accounts\" violates not-null constraint/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "bank_account_id foreign_key_constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id,
        bank_account_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_bank_account_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "entities_bank_accounts_entity_is_primary unique_constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      primary_bank_account = insert(:bank_account, org: org)

      _primary_entity_bank_account =
        insert(:entity_bank_account,
          org: org,
          entity: entity,
          bank_account: primary_bank_account,
          is_primary: true
        )

      another_bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id,
        bank_account_id: another_bank_account.id,
        is_primary: true
      }

      assert_raise Ecto.ConstraintError,
                   ~r/entities_bank_accounts_entity_is_primary \(unique_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "relationship_with_holder_not_null_when_is_holder_false constraint when is_holder is false" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id,
        bank_account_id: bank_account.id,
        is_holder: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/relationship_with_holder_not_null_when_is_holder_false \(check_constraint\)/,
                   fn -> Repo.insert(entity_bank_account) end
    end

    test "relationship_with_holder_not_null_when_is_holder_false constraint when is_holder is true" do
      org = insert(:org)
      entity = insert(:entity, org: org)
      bank_account = insert(:bank_account, org: org)

      entity_bank_account = %EntityBankAccount{
        org_id: org.id,
        entity_id: entity.id,
        bank_account_id: bank_account.id,
        is_holder: true,
        relationship_with_holder: :partner
      }

      assert_raise Ecto.ConstraintError,
                   ~r/relationship_with_holder_not_null_when_is_holder_false \(check_constraint\)/,
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
        is_active: false,
        is_holder: false,
        relationship_with_holder: random_enum_value(RelationshipWithHolder)
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               entity_id: attrs[:entity_id],
               bank_account_id: attrs[:bank_account_id],
               is_primary: attrs[:is_primary],
               is_active: attrs[:is_active],
               is_holder: attrs[:is_holder],
               relationship_with_holder: String.to_atom(attrs[:relationship_with_holder])
             }
    end

    test "missing required attrs" do
      assert changeset = EntityBankAccount.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               entity_id: ["can't be blank"],
               bank_account_id: ["can't be blank"]
             }
    end

    test "relationship_with_bank_account_holder required when is_holder is false" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_holder: false
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      refute changeset.valid?
      assert errors_on(changeset) == %{relationship_with_holder: ["can't be blank"]}
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        entity_id: :invalid,
        bank_account_id: :invalid,
        is_primary: :invalid,
        is_active: :invalid,
        is_holder: :invalid,
        relationship_with_holder: :invalid
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               entity_id: ["is invalid"],
               bank_account_id: ["is invalid"],
               is_primary: ["is invalid"],
               is_active: ["is invalid"],
               is_holder: ["is invalid"],
               relationship_with_holder: ["is invalid"]
             }
    end

    test "drops relationship_with_bank_account_holder when is_holder" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_holder: true,
        relationship_with_holder: random_enum_value(RelationshipWithHolder)
      }

      assert changeset = EntityBankAccount.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               entity_id: attrs[:entity_id],
               bank_account_id: attrs[:bank_account_id]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      entity_bank_account = insert(:entity_bank_account, is_primary: false, is_active: true)

      attrs = %{
        is_primary: true,
        is_active: false
      }

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               is_primary: attrs[:is_primary],
               is_active: attrs[:is_active]
             }
    end

    test "invalid attrs types" do
      entity_bank_account = insert(:entity_bank_account)

      attrs = %{
        is_primary: :invalid,
        is_active: :invalid
      }

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               is_primary: ["is invalid"],
               is_active: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      entity_bank_account = insert(:entity_bank_account, is_primary: false, is_active: true)

      attrs = %{
        is_primary: true,
        is_active: false,
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        bank_account_id: UUID.generate(),
        is_holder: false,
        relationship_with_holder: random_enum_value(RelationshipWithHolder)
      }

      assert changeset = EntityBankAccount.update_changeset(entity_bank_account, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               is_primary: attrs[:is_primary],
               is_active: attrs[:is_active]
             }
    end
  end
end
