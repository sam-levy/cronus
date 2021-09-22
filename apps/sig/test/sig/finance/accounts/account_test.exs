defmodule Sig.Finance.Banks.Accounts.AccountTest do
  use Sig.DataCase

  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.Account.BankAccountType

  describe "bank_accounts table constraints" do
    test "org_id not_null_violation" do
      account = %Account{
        type: random_enum_value(BankAccountType),
        routing_number: "123",
        branch_number: "456",
        number: "789"
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column "org_id" of relation "bank_accounts" violates not-null constraint/,
                   fn -> Repo.insert(account) end
    end

    test "org_id foreign_key_constraint" do
      account = %Account{
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: "123",
        branch_number: "456",
        number: "789"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "[org_id, pix_key] citext unique_constraint" do
      existing_account = insert(:bank_account, pix_key: "pix_key")

      account = %Account{
        org_id: existing_account.org_id,
        type: random_enum_value(BankAccountType),
        routing_number: "123",
        branch_number: "456",
        number: "789",
        pix_key: String.upcase(existing_account.pix_key)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_pix_key_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(account) end
    end

    test "[:org_id, :routing_number, :branch_number, :number] citext unique_constraint" do
      existing_account = insert(:bank_account,
        routing_number: "routing_number",
        branch_number: "branch_number",
        number: "number"
      )

      account = %Account{
        org_id: existing_account.org_id,
        type: random_enum_value(BankAccountType),
        routing_number: String.upcase(existing_account.routing_number),
        branch_number: String.upcase(existing_account.branch_number),
        number: String.upcase(existing_account.number),
      }

      assert_raise Ecto.ConstraintError,
                   ~r/bank_accounts_org_id_account \(unique_constraint\)/,
                   fn -> Repo.insert(account) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: random_bank_routing_number(),
        branch_number: "123",
        other_info: %{"OP" => "001"},
        number: "456",
        pix_key: "pix_key",
        is_active: false,
        is_joint_account: true
      }

      assert changeset = Account.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        type: String.to_atom(attrs[:type]),
        routing_number: attrs[:routing_number],
        branch_number: attrs[:branch_number],
        other_info: attrs[:other_info],
        number: attrs[:number],
        pix_key: attrs[:pix_key],
        is_active: attrs[:is_active],
        is_joint_account: attrs[:is_joint_account]
      }
    end

    test "missing required attrs" do
      assert changeset = Account.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
        org_id: ["can't be blank"],
        type: ["can't be blank"],
        routing_number: ["can't be blank"],
        branch_number: ["can't be blank"],
        number: ["can't be blank"]
      }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        type: 1,
        routing_number: :invalid,
        branch_number: :invalid,
        other_info: :invalid,
        number: :invalid,
        pix_key: :invalid,
        is_active: :invalid,
        is_joint_account: :invalid
      }

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        org_id: ["is invalid"],
        type: ["is invalid"],
        routing_number: ["is invalid"],
        branch_number: ["is invalid"],
        other_info: ["is invalid"],
        number: ["is invalid"],
        pix_key: ["is invalid"],
        is_active: ["is invalid"],
        is_joint_account: ["is invalid"]
      }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: random_bank_routing_number(),
        branch_number: String.duplicate("a", 256),
        number: String.duplicate("a", 256),
        pix_key: String.duplicate("a", 256)
      }

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        branch_number: ["should be at most 255 character(s)"],
        number: ["should be at most 255 character(s)"],
        pix_key: ["should be at most 255 character(s)"]
      }
    end

    test "invalid bank routing number" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: "invalid",
        branch_number: "123",
        number: "456"
      }

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        routing_number: ["does not exist"]
      }
    end

    test "pix key with white spaces" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: random_bank_routing_number(),
        branch_number: "123",
        number: "456",
        pix_key: "pix key",
      }

      assert changeset = Account.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        pix_key: ["can not have white spaces"],
      }
    end

    test "[pix_key, org_id] unique constraint" do
      org = insert(:org)
      existing_account = insert(:bank_account, org: org)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(BankAccountType),
        routing_number: random_bank_routing_number(),
        branch_number: "123",
        number: "456",
        pix_key: existing_account.pix_key
      }

      assert {:error, changeset} =
        attrs
        |> Account.create_changeset()
        |> Repo.insert()

      refute changeset.valid?
      assert errors_on(changeset) == %{pix_key: ["has already been taken"]}
    end

    test "[:org_id, :routing_number, :branch_number, :number] unique constraint" do
      org = insert(:org)

      existing_account = insert(:bank_account,
        org: org,
        routing_number: random_bank_routing_number(),
        branch_number: "branch_number",
        number: "number"
      )

      attrs = %{
        org_id: org.id,
        type: random_enum_value(BankAccountType),
        routing_number: String.upcase(existing_account.routing_number),
        branch_number: String.upcase(existing_account.branch_number),
        number: String.upcase(existing_account.number)
      }

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
      account = insert(:bank_account, pix_key: "pix_key", is_active: false)

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true
      }

      assert changeset = Account.update_changeset(account, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               pix_key: attrs[:pix_key],
               is_active: attrs[:is_active]
             }

    end

    test "invalid attrs types" do
      account = insert(:bank_account)

      attrs = %{
        pix_key: :invalid,
        is_active: :invalid
      }

      assert changeset = Account.update_changeset(account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               pix_key: ["is invalid"],
               is_active: ["is invalid"]
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
               pix_key: ["should be at most 255 character(s)"],
             }
    end

    test "pix key with white spaces" do
      account = insert(:bank_account)

      attrs = %{
        pix_key: "pix key",
      }

      assert changeset = Account.update_changeset(account, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
              pix_key: ["can not have white spaces"],
            }
    end

    test "ignores non permitted attrs" do
      account = insert(:bank_account, pix_key: "pix_key", is_active: false)

      attrs = %{
        pix_key: "new_pix_key",
        is_active: true,
        org_id: UUID.generate(),
        type: random_enum_value(BankAccountType),
        routing_number: random_bank_routing_number(),
        branch_number: "123",
        other_info: %{"OP" => "001"},
        number: "456",
        is_joint_account: true
      }

      assert changeset = Account.update_changeset(account, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               pix_key: attrs[:pix_key],
               is_active: attrs[:is_active]
             }
    end

    test "[pix_key, org_id] unique constraint" do
      org = insert(:org)

      account_1 = insert(:bank_account, org: org)
      account_2 = insert(:bank_account, org: org)

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
