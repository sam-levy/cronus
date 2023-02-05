defmodule Sig.Accounting.LedgerCategories.LedgerCategoryTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.LedgerCategories.LedgerCategory

  describe "changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        code: random_string_number(5),
        description: Faker.Commerce.department(),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: UUID.generate()
      }

      assert changeset = LedgerCategory.changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               chart_of_account_id: attrs[:chart_of_account_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        code: :invalid,
        description: :invalid,
        entry_type: :invalid,
        chart_of_account_id: :invalid
      }

      assert changeset = LedgerCategory.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               code: ["is invalid"],
               description: ["is invalid"],
               entry_type: ["is invalid"],
               chart_of_account_id: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = LedgerCategory.changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               code: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"],
               chart_of_account_id: ["can't be blank"]
             }
    end

    test "string fields length greater than limit" do
      attrs = %{
        org_id: UUID.generate(),
        code: String.duplicate("1", 256),
        description: String.duplicate("a", 256),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: UUID.generate()
      }

      assert changeset = LedgerCategory.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["should be at most 255 character(s)"],
               description: ["should be at most 255 character(s)"]
             }
    end

    test "string code numericality" do
      attrs = %{
        org_id: UUID.generate(),
        code: "NAN",
        description: Faker.Commerce.department(),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: UUID.generate()
      }

      assert changeset = LedgerCategory.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has invalid format"]
             }
    end

    test "chart_of_account assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        code: random_string_number(5),
        description: Faker.Commerce.department(),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> LedgerCategory.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               chart_of_account: ["does not exist"]
             }
    end

    test "[:code, :chart_of_account_id, :org_id] unique constraint" do
      org = insert(:org)
      chart_of_account = insert(:chart_of_account, org: org)
      code = random_string_number(5)

      insert(:ledger_category, org: org, code: code, chart_of_account: chart_of_account)

      attrs = %{
        org_id: org.id,
        code: code,
        description: Faker.Commerce.department(),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: chart_of_account.id
      }

      assert {:error, changeset} =
               attrs
               |> LedgerCategory.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has already been taken"]
             }
    end

    test "[:description, :chart_of_account_id, :org_id] unique constraint" do
      org = insert(:org)
      chart_of_account = insert(:chart_of_account, org: org)
      description = Faker.Commerce.department()

      insert(:ledger_category,
        org: org,
        description: description,
        chart_of_account: chart_of_account
      )

      attrs = %{
        org_id: org.id,
        code: random_string_number(5),
        description: description,
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: chart_of_account.id
      }

      assert {:error, changeset} =
               attrs
               |> LedgerCategory.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["has already been taken"]
             }
    end

    test "insert changeset" do
      org = insert(:org)
      chart_of_account = insert(:chart_of_account, org: org)

      attrs = %{
        org_id: org.id,
        code: random_string_number(5),
        description: Faker.Commerce.department(),
        entry_type: random_enum_value(:entry_type),
        chart_of_account_id: chart_of_account.id
      }

      assert {:ok, _ledger_category} =
               attrs
               |> LedgerCategory.changeset()
               |> Repo.insert()
    end
  end
end
