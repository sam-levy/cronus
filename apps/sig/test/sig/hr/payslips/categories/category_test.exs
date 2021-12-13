defmodule Sig.HR.Payslips.Categories.CategoryTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Categories.Category

  describe "payslip_categories table constraints" do
    test "org_id not_null_violation" do
      category = %Category{
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        is_payment_advance: false
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_categories\" violates not-null constraint/,
                   fn -> Repo.insert(category) end
    end

    test "org_id foreign_key_constraint" do
      category = %Category{
        org_id: UUID.generate(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_categories_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(category) end
    end

    test "[:code, :org_id] payslip_categories_code_unique citext unique_constraint" do
      org = insert(:org)

      _existing_payslip_category =
        insert(:payslip_category, org: org, code: "PAYSLIP_CATEGORY_CODE")

      # Allow same code for different org
      insert(:payslip_category, code: "PAYSLIP_CATEGORY_CODE")

      category = %Category{
        org_id: org.id,
        code: "payslip_category_code",
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_categories_code_unique \(unique_constraint\)/,
                   fn -> Repo.insert(category) end
    end

    test "payslip_categories_is_payment_advance_entry_type_debit constraint" do
      org = insert(:org)

      category = %Category{
        org_id: org.id,
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        is_payment_advance: true
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_categories_is_payment_advance_entry_type_debit \(check_constraint\)/,
                   fn -> Repo.insert(category) end
    end

    test "success" do
      org = insert(:org)

      category = %Category{
        org_id: org.id,
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type)
      }

      assert Repo.insert!(category)
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        is_payment_advance: false
      }

      assert changeset = Category.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               is_payment_advance: attrs[:is_payment_advance]
             }
    end

    test "missing required attrs" do
      assert changeset = Category.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"],
               org_id: ["can't be blank"]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        code: :invalid,
        description: :invalid,
        entry_type: :invalid,
        is_payment_advance: :invalid
      }

      assert changeset = Category.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["is invalid"],
               description: ["is invalid"],
               entry_type: ["is invalid"],
               is_payment_advance: ["is invalid"],
               org_id: ["is invalid"]
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        code: String.duplicate("a", 256),
        description: String.duplicate("a", 256),
        entry_type: :credit,
        is_payment_advance: false
      }

      assert changeset = Category.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["should be at most 255 character(s)"],
               description: ["should be at most 255 character(s)"]
             }
    end

    test "code unique constraint" do
      org = insert(:org)
      _existing_category = insert(:payslip_category, org: org, code: "PAYSLIP_CATEGORY_CODE")

      attrs = %{
        org_id: org.id,
        code: "payslip_category_code",
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        is_payment_advance: false
      }

      {:error, changeset} =
        attrs
        |> Category.create_changeset()
        |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has already been taken"]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        code: "New Code",
        description: "New Description",
        entry_type: :credit,
        is_payment_advance: false
      }

      assert changeset = Category.update_changeset(category, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               is_payment_advance: attrs[:is_payment_advance]
             }
    end

    test "nil required attrs" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        code: nil,
        description: nil,
        entry_type: nil,
      }

      assert changeset = Category.update_changeset(category, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        org_id: UUID.generate(),
        code: "New Code",
        description: "New Description",
        entry_type: :credit,
        is_payment_advance: false
      }

      assert changeset = Category.update_changeset(category, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               is_payment_advance: attrs[:is_payment_advance]
             }
    end

    test "string fields length greater than 255 chars" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        code: String.duplicate("a", 256),
        description: String.duplicate("a", 256),
        entry_type: :credit,
        is_payment_advance: false
      }

      assert changeset = Category.update_changeset(category, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["should be at most 255 character(s)"],
               description: ["should be at most 255 character(s)"]
             }
    end

    test "code unique constraint" do
      org = insert(:org)
      _existing_category = insert(:payslip_category, org: org, code: "PAYSLIP_CATEGORY_CODE")

      category = insert(:payslip_category, org: org, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        code: "payslip_category_code",
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        is_payment_advance: false
      }

      {:error, changeset} =
        category
        |> Category.update_changeset(attrs)
        |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has already been taken"]
             }
    end
  end
end
