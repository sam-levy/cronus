defmodule Sig.Finance.Banks.Accounts.AccountTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account

  describe "bank_accounts table constraints" do
    test "insertion" do
      entity = insert(:entity)

      account = %Account{
        org_id: entity.org_id,
        entity_id: entity.id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert {:ok, _} = Repo.insert(account)
    end

    test "org_id not_null_violation" do
      entity = insert(:entity)

      account = %Account{
        entity_id: entity.id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "bank_accounts" violates not-null constraint/,
                   fn -> Repo.insert(account) end
    end

    test "org_id foreign_key_constraint" do
      entity = insert(:entity)

      account = %Account{
        org_id: UUID.generate(),
        entity_id: entity.id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "entity_id not_null_violation" do
      org = insert(:org)

      account = %Account{
        org_id: org.id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "entity_id" of relation "bank_accounts" violates not-null constraint/,
                   fn -> Repo.insert(account) end
    end

    test "entity_id foreign_key_constraint" do
      org = insert(:org)

      account = %Account{
        org_id: org.id,
        entity_id: UUID.generate(),
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_entity_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "[pix_key, org_id] citext unique_constraint" do
      existing_account = insert(:bank_account, pix_key: "pix_key", is_primary: true)

      account = %Account{
        org_id: existing_account.org_id,
        entity_id: existing_account.entity_id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false,
        pix_key: String.upcase(existing_account.pix_key)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_pix_key_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "[:routing_number, :branch_number, :number, :org_id] citext unique_constraint" do
      existing_account =
        insert(:bank_account,
          routing_number: "routing_number",
          branch_number: "branch_number",
          number: "number",
          is_primary: true
        )

      account = %Account{
        org_id: existing_account.org_id,
        entity_id: existing_account.entity_id,
        type: random_enum_value(:bank_account_type),
        routing_number: String.upcase(existing_account.routing_number),
        branch_number: String.upcase(existing_account.branch_number),
        number: String.upcase(existing_account.number),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_org_id_account \(unique_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "bank_accounts_is_primary unique_constraint" do
      org = insert(:org)
      entity_1 = insert(:entity, org: org)
      entity_2 = insert(:entity, org: org)

      # Allow is_primary = true for different entities from the same org
      _entity_1_primary = insert(:bank_account, org: org, entity: entity_1, is_primary: true)
      _entity_2_primary = insert(:bank_account, org: org, entity: entity_2, is_primary: true)

      entity_2_duplicated_primary = %Account{
        org_id: org.id,
        entity_id: entity_2.id,
        type: random_enum_value(:bank_account_type),
        routing_number: random_string_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        is_active: true,
        is_primary: true,
        is_joint_account: false
      }

      # Rises if is_primary = true for a second account of an entity with a primary account
      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_is_primary \(unique_constraint\)/,
                   fn -> Repo.insert(entity_2_duplicated_primary) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
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

      assert changeset = Account.create_changeset(attrs)

      assert changeset.valid?
      assert changeset.changes == attrs
    end

    test "missing required attrs" do
      assert changeset = Account.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               entity_id: ["can't be blank"],
               type: ["can't be blank"],
               routing_number: ["can't be blank"],
               branch_number: ["can't be blank"],
               number: ["can't be blank"],
               is_primary: ["can't be blank"],
               is_active: ["can't be blank"],
               is_joint_account: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        entity_id: :invalid,
        type: 1,
        routing_number: :invalid,
        branch_number: :invalid,
        number: :invalid,
        other_info: :invalid,
        pix_key: :invalid,
        is_active: :invalid,
        is_primary: :invalid,
        is_joint_account: :invalid
      }

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               entity_id: ["is invalid"],
               type: ["is invalid"],
               routing_number: ["is invalid"],
               branch_number: ["is invalid"],
               number: ["is invalid"],
               other_info: ["is invalid"],
               pix_key: ["is invalid"],
               is_active: ["is invalid"],
               is_primary: ["is invalid"],
               is_joint_account: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = attrs_for(:bank_account,
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        branch_number: String.duplicate("a", 256),
        number: String.duplicate("a", 256),
        pix_key: String.duplicate("a", 256)
      )

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               branch_number: ["should be at most 255 character(s)"],
               number: ["should be at most 255 character(s)"],
               pix_key: ["should be at most 255 character(s)"]
             }
    end

    test "invalid bank routing number" do
      attrs = attrs_for(:bank_account,
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        routing_number: "invalid"
      )

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               routing_number: ["does not exist"]
             }
    end

    test "pix key with white spaces" do
      attrs = attrs_for(:bank_account,
        org_id: UUID.generate(),
        entity_id: UUID.generate(),
        pix_key: "pix key"
      )

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               pix_key: ["can't have white spaces"]
             }
    end

    test "[pix_key, org_id] unique constraint" do
      existing_account = insert(:bank_account, is_primary: true, pix_key: "pix_key")

      attrs = attrs_for(:bank_account,
        org_id: existing_account.org_id,
        entity_id: existing_account.entity_id,
        pix_key: existing_account.pix_key,
        is_primary: false,
      )

      assert {:error, changeset} =
               attrs
               |> Account.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{pix_key: ["has already been taken"]}
    end

    test "[:routing_number, :branch_number, :number, :org_id] unique constraint" do
      existing_account =
        insert(:bank_account,
          routing_number: random_bank_routing_number(),
          branch_number: "branch_number",
          number: "number",
          is_primary: true
        )

      attrs = attrs_for(:bank_account,
        org_id: existing_account.org_id,
        entity_id: existing_account.entity_id,
        routing_number: String.upcase(existing_account.routing_number),
        branch_number: String.upcase(existing_account.branch_number),
        number: String.upcase(existing_account.number),
        is_primary: false,
      )

      assert {:error, changeset} =
               attrs
               |> Account.create_changeset()
               |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{routing_number: ["has already been taken"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      existing_bank_account = insert(:bank_account, is_primary: false)

      account =
        insert(:bank_account,
          org: existing_bank_account.org,
          entity: existing_bank_account.entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        is_primary: true
      }

      assert changeset = Account.update_changeset(account, attrs)

      assert changeset.valid?
      assert changeset.changes == attrs
    end

    test "invalid attrs types" do
      account = insert(:bank_account)

      attrs = %{
        pix_key: :invalid,
        is_active: :invalid,
        is_primary: :invalid
      }

      assert changeset = Account.update_changeset(account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               pix_key: ["is invalid"],
               is_active: ["is invalid"],
               is_primary: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      account = insert(:bank_account)

      attrs = %{
        pix_key: String.duplicate("a", 256)
      }

      assert changeset = Account.update_changeset(account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               pix_key: ["should be at most 255 character(s)"]
             }
    end

    test "pix key with white spaces" do
      account = insert(:bank_account)

      attrs = %{
        pix_key: "pix key"
      }

      assert changeset = Account.update_changeset(account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               pix_key: ["can't have white spaces"]
             }
    end

    test "ignores non permitted attrs" do
      existing_bank_account = insert(:bank_account, is_primary: true)

      account =
        insert(:bank_account,
          org: existing_bank_account.org,
          entity: existing_bank_account.entity,
          pix_key: "pix_key",
          is_active: false,
          is_primary: false
        )

      attrs = %{
        pix_key: "new_pix_key",
        org_id: UUID.generate(),
        type: random_enum_value(:bank_account_type),
        routing_number: random_bank_routing_number(),
        branch_number: random_string_number(),
        number: random_string_number(),
        other_info: %{"OP" => "001"},
        is_active: true,
        is_primary: true,
        is_joint_account: true
      }

      assert changeset = Account.update_changeset(account, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               pix_key: attrs[:pix_key],
               is_active: attrs[:is_active],
               is_primary: attrs[:is_primary]
             }
    end

    test "[pix_key, org_id] unique constraint" do
      org = insert(:org)

      account_1 = insert(:bank_account, org: org, is_active: true)
      account_2 = insert(:bank_account, org: org, is_active: false, pix_key: "pix_key_ac_2")

      attrs = %{
        pix_key: account_2.pix_key
      }

      assert {:error, changeset} =
               account_1
               |> Account.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?
      assert errors_on(changeset) == %{pix_key: ["has already been taken"]}
    end
  end
end
