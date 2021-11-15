defmodule Sig.HR.Payslips.Items.ItemTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Items.Item

  describe "payslip_items table base constraints" do
    test "org_id not_null_violation" do
      payslip = insert(:payslip)
      category = insert(:payslip_category, org: payslip.org)

      item = %Item{
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_items\" violates not-null constraint/,
                   fn -> Repo.insert(item) end
    end

    test "org_id foreign_key_constraint" do
      payslip = insert(:payslip)
      category = insert(:payslip_category, org: payslip.org)

      item = %Item{
        org_id: UUID.generate(),
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "payslip_items_amount_positive constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: -1,
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_amount_positive \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "payslip_items_is_payment_advance_entry_type_debit constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        amount: 100_00,
        payslip_id: payslip.id,
        category_id: category.id,
        entry_type: :credit,
        is_payment_advance: true
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_is_payment_advance_entry_type_debit \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "insertion when payslip is closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: true, amount: 0)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: 100_00,
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) closed payslip cannot be updated/,
                   fn -> Repo.insert(item) end
    end

    test "update when payslip is closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)
      category = insert(:payslip_category, org: org, entry_type: :credit)

      item =
        insert(:payslip_item,
          org: org,
          reference: "30 dias",
          description: Faker.Lorem.sentence(),
          entry_type: :credit,
          amount: 100_00,
          payslip: payslip,
          category: category
        )

      # close payslip
      Repo.update!(change(payslip, amount: 100_00, is_closed: true))

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) closed payslip cannot be updated/,
                   fn -> Repo.update(change(item, reference: "28 dias")) end
    end

    test "deletion when payslip is closed" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, is_closed: false)
      category = insert(:payslip_category, org: org, entry_type: :credit)

      item =
        insert(:payslip_item,
          org: org,
          reference: random_string_number(),
          description: Faker.Lorem.sentence(),
          entry_type: :credit,
          amount: 100_00,
          payslip: payslip,
          category: category
        )

      # close payslip
      Repo.update!(change(payslip, amount: 100_00, is_closed: true))

      assert_raise Postgrex.Error,
                   ~r/\(integrity_constraint_violation\) closed payslip cannot be updated/,
                   fn -> Repo.delete(item) end
    end
  end

  describe "payslip_items table `payslip_item` type conditional constraints" do
    test "payslip_items_category_unique unique_index" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      insert(:payslip_item, org: org, payslip: payslip, category: category)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_category_unique \(unique_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "category_id IS NOT NULL" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "code IS NULL" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "inserts" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :payslip_item,
        code: random_string_number(),
        reference: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert {:ok, _return} = Repo.insert(item)
    end
  end

  describe "payslip_items table `outside_item` type conditional constraints" do
    test "category_id IS NULL" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      item = %Item{
        org_id: org.id,
        type: :outside_item,
        amount: Enum.random(100_00..300_00),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "reference IS NULL" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      item = %Item{
        org_id: org.id,
        type: :outside_item,
        amount: Enum.random(100_00..300_00),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        payslip_id: payslip.id,
        reference: random_string_number()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "code IS NULL" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      item = %Item{
        org_id: org.id,
        type: :outside_item,
        amount: Enum.random(100_00..300_00),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        payslip_id: payslip.id,
        code: random_string_number()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(item) end
    end

    test "inserts" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      item = %Item{
        org_id: org.id,
        type: :outside_item,
        amount: Enum.random(100_00..300_00),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        payslip_id: payslip.id
      }

      assert {:ok, _return} = Repo.insert(item)
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        reference: random_string_number(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate(),
        category_id: UUID.generate(),
        is_payment_advance: true
      }

      assert changeset = Item.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               reference: attrs[:reference],
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               payslip_id: attrs[:payslip_id],
               category_id: attrs[:category_id],
               is_payment_advance: attrs[:is_payment_advance],
               type: :payslip_item
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        reference: :invalid,
        code: :invalid,
        description: :invalid,
        entry_type: :invalid,
        amount: :invalid,
        payslip_id: :invalid,
        category_id: :invalid,
        is_payment_advance: :invalid
      }

      assert changeset = Item.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["is invalid"],
               description: ["is invalid"],
               entry_type: ["is invalid"],
               code: ["is invalid"],
               category_id: ["is invalid"],
               org_id: ["is invalid"],
               payslip_id: ["is invalid"],
               reference: ["is invalid"],
               is_payment_advance: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Item.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               description: ["can't be blank"],
               code: ["can't be blank"],
               entry_type: ["can't be blank"],
               category_id: ["can't be blank"],
               org_id: ["can't be blank"],
               payslip_id: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        reference: random_string_number(),
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate(),
        category_id: UUID.generate(),
        is_payment_advance: false
      }

      assert changeset = Item.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               reference: attrs[:reference],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               payslip_id: attrs[:payslip_id],
               category_id: attrs[:category_id],
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               type: :payslip_item
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        reference: String.duplicate("a", 256),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate(),
        category_id: UUID.generate()
      }

      assert changeset = Item.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               reference: ["should be at most 255 character(s)"]
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        reference: random_string_number(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: -1,
        payslip_id: UUID.generate(),
        category_id: UUID.generate()
      }

      assert changeset = Item.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "category assoc constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      attrs = %{
        org_id: org.id,
        reference: random_string_number(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> Item.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               category: ["does not exist"]
             }
    end

    test "category_id unique constraint" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      insert(:payslip_item, org: org, payslip: payslip, category: category)

      attrs = %{
        org_id: org.id,
        reference: random_string_number(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id
      }

      assert {:error, changeset} =
               attrs
               |> Item.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               category_id: ["has already been taken"]
             }
    end
  end

  describe "create_outside_item_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate()
      }

      assert changeset = Item.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               payslip_id: attrs[:payslip_id],
               type: :outside_item
             }
    end

    test "invalid attrs" do
      assert changeset = Item.create_outside_item_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               org_id: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"],
               payslip_id: ["can't be blank"]
             }
    end

    test "misssing required attrs" do
      attrs = %{
        org_id: :invalid,
        description: :invalid,
        entry_type: :invalid,
        amount: :invalid,
        payslip_id: :invalid
      }

      assert changeset = Item.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["is invalid"],
               org_id: ["is invalid"],
               payslip_id: ["is invalid"],
               description: ["is invalid"],
               entry_type: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        reference: random_string_number(),
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate(),
        category_id: UUID.generate()
      }

      assert changeset = Item.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               payslip_id: attrs[:payslip_id],
               type: :outside_item
             }
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        description: String.duplicate("a", 256),
        entry_type: random_enum_value(:entry_type),
        amount: Enum.random(100_00..300_00),
        payslip_id: UUID.generate()
      }

      assert changeset = Item.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["should be at most 255 character(s)"]
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        amount: -1,
        payslip_id: UUID.generate()
      }

      assert changeset = Item.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "payment advance validation" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        org_id: org.id,
        reference: random_string_number(),
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        amount: Enum.random(100_00..300_00),
        payslip_id: payslip.id,
        category_id: category.id,
        entry_type: :credit,
        is_payment_advance: true
      }

      assert {:error, changeset} =
               attrs
               |> Item.create_outside_item_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               entry_type: ["must be debit when is_payment_advance is true"]
             }
    end
  end

  describe "update_amount_changeset/2" do
    test "valid attrs" do
      item = insert(:payslip_item, amount: 100_00)
      attrs = %{amount: 200_00}

      assert changeset = Item.update_amount_changeset(item, attrs)

      assert changeset.valid?

      assert changeset.changes == %{amount: %Money{amount: 200_00, currency: :BRL}}
    end

    test "ignores non permitted attrs" do
      item = insert(:payslip_item, amount: 200_00)

      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        entry_type: random_enum_value(:entry_type),
        reference: random_string_number(),
        amount: 100_00,
        payslip_id: UUID.generate(),
        category_id: UUID.generate()
      }

      assert changeset = Item.update_amount_changeset(item, attrs)

      assert changeset.valid?

      assert changeset.changes == %{amount: %Money{amount: 100_00, currency: :BRL}}
    end
  end
end
