defmodule Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItemTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem

  describe "employee_registration_recurring_payslip_items table base constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      recurring_payslip_item = %RecurringPayslipItem{
        registration_id: registration.id,
        type: :outside_item,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_registration_recurring_payslip_items\" violates not-null constraint/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: UUID.generate(),
        registration_id: registration.id,
        type: :outside_item,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        type: :outside_item,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_registration_recurring_payslip_items\" violates not-null constraint/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: UUID.generate(),
        type: :outside_item,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_registration_id_f \(foreign_key_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "[:outside_item_description, :registration_id, :org_id] employee_registration_recurring_payslip_items_description citext unique_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_description: "DESCRIPTION"
      )

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        outside_item_description: "description",
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_description \(unique_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "employee_registration_recurring_payslip_items_positive_amount constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        item_amount: -1
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_positive_amount \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end
  end

  describe "employee_registration_recurring_payslip_items table `payslip_item` type conditional constraints" do
    test "success" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        payslip_category_id: category.id,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, _item} = Repo.insert(recurring_payslip_item)
    end

    test "item_amount IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        payslip_category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_category_id IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_recurring_item_model_id IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        item_amount: Enum.random(100_00..5_000_00),
        payslip_category_id: category.id,
        payslip_recurring_item_model_id: recurring_item_model.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_description IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        item_amount: Enum.random(100_00..5_000_00),
        payslip_category_id: category.id,
        outside_item_description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_entry_type IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        item_amount: Enum.random(100_00..5_000_00),
        payslip_category_id: category.id,
        outside_item_entry_type: random_enum_value(:entry_type)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_is_payment_advance IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item,
        item_amount: Enum.random(100_00..5_000_00),
        payslip_category_id: category.id,
        outside_item_is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end
  end

  describe "employee_registration_recurring_payslip_items table `payslip_item_model` type conditional constraints" do
    test "success" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id
      }

      assert {:ok, _item} = Repo.insert(recurring_payslip_item)
    end

    test "item_amount IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_category_id IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id,
        payslip_category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_recurring_item_model_id IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_description IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id,
        outside_item_description: Faker.Lorem.sentence()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_entry_type IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id,
        outside_item_entry_type: random_enum_value(:entry_type)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_is_payment_advance IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :payslip_item_model,
        payslip_recurring_item_model_id: recurring_item_model.id,
        outside_item_is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end
  end

  describe "employee_registration_recurring_payslip_items table `outside_item` type conditional constraints" do
    test "success" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert {:ok, _item} = Repo.insert(recurring_payslip_item)
    end

    test "item_amount IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        payslip_recurring_item_model_id: recurring_item_model.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_category_id IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      category = insert(:payslip_category, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        payslip_category_id: category.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "payslip_recurring_item_model_id IS NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      recurring_item_model = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false,
        payslip_recurring_item_model_id: recurring_item_model.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_description IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_entry_type IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_is_payment_advance: false
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "outside_item_is_payment_advance IS NOT NULL" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end

    test "employee_registration_recurring_payslip_items_payment_advance check_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      recurring_payslip_item = %RecurringPayslipItem{
        org_id: org.id,
        registration_id: registration.id,
        type: :outside_item,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: :credit,
        outside_item_is_payment_advance: true
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_registration_recurring_payslip_items_payment_advance \(check_constraint\)/,
                   fn -> Repo.insert(recurring_payslip_item) end
    end
  end

  describe "create_payslip_item_changeset/1" do
    test "missing required attrs" do
      assert changeset = RecurringPayslipItem.create_payslip_item_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"],
               item_amount: ["can't be blank"],
               payslip_category_id: ["can't be blank"]
             }
    end

    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :payslip_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL}
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        payslip_category_id: :invalid,
        item_amount: :invalid
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               item_amount: ["is invalid"],
               org_id: ["is invalid"],
               payslip_category_id: ["is invalid"],
               registration_id: ["is invalid"]
             }
    end

    test "positive item_amount" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        item_amount: -1
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               item_amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: "to be ignored",
        payslip_category_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00),
        payslip_recurring_item_model_id: UUID.generate(),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :payslip_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL}
             }
    end

    test "payslip_category assoc constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        payslip_category_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert {:error, changeset} =
               attrs
               |> RecurringPayslipItem.create_payslip_item_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               payslip_category: ["does not exist"]
             }
    end

    test "inserts item" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        payslip_category_id: category.id,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, %RecurringPayslipItem{}} =
               attrs
               |> RecurringPayslipItem.create_payslip_item_changeset()
               |> Repo.insert()
    end
  end

  describe "create_payslip_item_model_changeset/1" do
    test "missing required attrs" do
      assert changeset = RecurringPayslipItem.create_payslip_item_model_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_recurring_item_model_id: ["can't be blank"],
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"]
             }
    end

    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_model_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :payslip_item_model,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        payslip_recurring_item_model_id: :invalid
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_model_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               payslip_recurring_item_model_id: ["is invalid"],
               registration_id: ["is invalid"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: "to be ignored",
        payslip_category_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00),
        payslip_recurring_item_model_id: UUID.generate(),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_payslip_item_model_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :payslip_item_model,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id]
             }
    end

    test "payslip_recurring_item_model assoc constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> RecurringPayslipItem.create_payslip_item_model_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               payslip_recurring_item_model: ["does not exist"]
             }
    end

    test "inserts item" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        payslip_recurring_item_model_id: payslip_recurring_item_model.id
      }

      assert {:ok, %RecurringPayslipItem{}} =
               attrs
               |> RecurringPayslipItem.create_payslip_item_model_changeset()
               |> Repo.insert()
    end
  end

  describe "create_outside_item_changeset/1" do
    test "missing required attrs" do
      assert changeset = RecurringPayslipItem.create_outside_item_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               item_amount: ["can't be blank"],
               outside_item_description: ["can't be blank"],
               outside_item_entry_type: ["can't be blank"],
               org_id: ["can't be blank"],
               registration_id: ["can't be blank"]
             }
    end

    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :outside_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL},
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: attrs[:outside_item_is_payment_advance]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        item_amount: :invalid,
        outside_item_description: :invalid,
        outside_item_entry_type: :invalid,
        outside_item_is_payment_advance: :invalid
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               item_amount: ["is invalid"],
               org_id: ["is invalid"],
               outside_item_description: ["is invalid"],
               outside_item_entry_type: ["is invalid"],
               outside_item_is_payment_advance: ["is invalid"],
               registration_id: ["is invalid"]
             }
    end

    test "positive item_amount" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        item_amount: -1,
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               item_amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "outside_item_description length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: String.duplicate("a", 256),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               outside_item_description: ["should be at most 255 character(s)"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        type: "to be ignored",
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        item_amount: Enum.random(100_00..5_000_00),
        payslip_recurring_item_model_id: UUID.generate(),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :outside_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL},
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: attrs[:outside_item_is_payment_advance]
             }
    end

    test "outside_item_entry_type credit when outside_item_is_payment_advance is true" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: "description",
        outside_item_entry_type: :credit,
        outside_item_is_payment_advance: true
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               outside_item_is_payment_advance: [
                 "must be false when outside_item_entry_type is credit"
               ]
             }
    end

    test "put missing outside_item_entry_type false when outside_item_entry_type is credit" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: "description",
        outside_item_entry_type: :credit
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :outside_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL},
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: false
             }
    end

    test "put missing outside_item_entry_type false when outside_item_entry_type is debit" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: "description",
        outside_item_entry_type: :debit
      }

      assert changeset = RecurringPayslipItem.create_outside_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: :outside_item,
               org_id: attrs[:org_id],
               registration_id: attrs[:registration_id],
               item_amount: %Money{amount: attrs[:item_amount], currency: :BRL},
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: false
             }
    end

    test "outside_item_description citext unique constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_description: "DESCRIPTION"
      )

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: "description",
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert {:error, changeset} =
               attrs
               |> RecurringPayslipItem.create_outside_item_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               outside_item_description: ["has already been taken"]
             }
    end

    test "inserts" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        org_id: org.id,
        registration_id: registration.id,
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: random_enum_value(:entry_type),
        outside_item_is_payment_advance: false
      }

      assert {:ok, %RecurringPayslipItem{}} =
               attrs
               |> RecurringPayslipItem.create_outside_item_changeset()
               |> Repo.insert()
    end
  end
end
