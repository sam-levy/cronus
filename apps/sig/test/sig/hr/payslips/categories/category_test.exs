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
        entry_type: random_enum_value(:entry_type),
      }

      assert Repo.insert!(category)
    end
  end
end
