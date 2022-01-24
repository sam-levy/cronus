defmodule Sig.HR.Payslips.RecurringItemModels.RecurringItemModelTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel

  describe "payslip_recurring_item_models table constraints" do
    test "org_id not_null_violation" do
      model = %RecurringItemModel{
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: insert(:payslip_category).id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_recurring_item_models\" violates not-null constraint/,
                   fn -> Repo.insert(model) end
    end

    test "org_id foreign_key_constraint" do
      model = %RecurringItemModel{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "category_id not_null_violation" do
      model = %RecurringItemModel{
        org_id: insert(:payslip_category).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"category_id\" of relation \"payslip_recurring_item_models\" violates not-null constraint/,
                   fn -> Repo.insert(model) end
    end

    test "[:description, :org_id] payslip_recurring_item_models_description_org_id_index citext unique_constraint" do
      org = insert(:org)

      _existing_recurring_item_model =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          description: "RECURRING ITEM MODEL"
        )

      # Allow same description for different org
      insert({:payslip_recurring_item_model, :fixed_amount}, description: "RECURRING ITEM MODEL")

      model = %RecurringItemModel{
        org_id: org.id,
        description: "recurring item model",
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_description_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_positive_amount constraint" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: -1,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_positive_amount \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_percentage_range constraint less than 0" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: -1,
        percentage_target: :employee_salary,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_percentage_range \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_percentage_range constraint more than 100" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 101,
        percentage_target: :employee_salary,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_percentage_range \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_fixed_amount_conditional must have amount when is_fixed_amount is true" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        percentage: 40,
        percentage_target: :employee_salary,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_fixed_amount_conditional \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_fixed_amount_conditional can't have amount when is_fixed_amount is false" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        amount: Enum.random(100_00..1_000_00),
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_fixed_amount_conditional \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_percentage_target_conditional must have employee_benefit_type_percentage_target when percentage_target is employee_benefit" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 40,
        percentage_target: :employee_benefit,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_percentage_target_conditional \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end

    test "payslip_recurring_item_models_percentage_target_conditional can't have employee_benefit_type_percentage_target when percentage_target is employee_salary" do
      model = %RecurringItemModel{
        org_id: insert(:org).id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 40,
        percentage_target: :employee_salary,
        employee_benefit_type_percentage_target: :transportation_voucher,
        category_id: insert(:payslip_category).id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_recurring_item_models_percentage_target_conditional \(check_constraint\)/,
                   fn -> Repo.insert(model) end
    end
  end

  describe "create_changeset/1" do
    test "missing required base attrs" do
      assert changeset = RecurringItemModel.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               category_id: ["can't be blank"],
               description: ["can't be blank"],
               is_fixed_amount: ["can't be blank"],
               org_id: ["can't be blank"]
             }
    end

    test "valid attrs for fixed amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               category_id: attrs[:category_id]
             }
    end

    test "drops non permitted attrs for fixed amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: UUID.generate(),
        percentage: 6,
        percentage_target: :employee_benefit,
        employee_benefit_type_percentage_target: :transportation_voucher
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               category_id: attrs[:category_id]
             }
    end

    test "missing required attrs for fixed amount" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{amount: ["can't be blank"]}
    end

    test "string fields length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        description: String.duplicate("a", 256),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end

    test "inserts fixed amount" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: category.id
      }

      assert {:ok, %RecurringItemModel{}} =
               attrs
               |> RecurringItemModel.create_changeset()
               |> Repo.insert()
    end

    test "valid attrs for percentage of employee salary" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 20,
        percentage_target: :employee_salary,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               percentage: attrs[:percentage],
               percentage_target: attrs[:percentage_target],
               category_id: attrs[:category_id]
             }
    end

    test "drops non permitted attrs for percentage of employee salary" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 20,
        percentage_target: :employee_salary,
        category_id: UUID.generate(),
        amount: Enum.random(100_00..1_000_00),
        employee_benefit_type_percentage_target: :transportation_voucher
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               percentage: attrs[:percentage],
               percentage_target: attrs[:percentage_target],
               category_id: attrs[:category_id]
             }
    end

    test "missing attrs for percentage of employee salary" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               percentage: ["can't be blank"],
               percentage_target: ["can't be blank"]
             }
    end

    test "validates percentage inclusion for less than 0" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: -1,
        percentage_target: :employee_salary,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{percentage: ["is invalid"]}
    end

    test "validates percentage inclusion for more than 100" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 101,
        percentage_target: :employee_salary,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{percentage: ["is invalid"]}
    end

    test "inserts percentage of employee salary" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 20,
        percentage_target: :employee_salary,
        category_id: category.id
      }

      assert {:ok, %RecurringItemModel{}} =
               attrs
               |> RecurringItemModel.create_changeset()
               |> Repo.insert()
    end

    test "valid attrs for percentage of employee benefit" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 6,
        percentage_target: :employee_benefit,
        employee_benefit_type_percentage_target: :transportation_voucher,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               percentage: attrs[:percentage],
               percentage_target: attrs[:percentage_target],
               employee_benefit_type_percentage_target:
                 attrs[:employee_benefit_type_percentage_target],
               category_id: attrs[:category_id]
             }
    end

    test "drops non permitted attrs for percentage of employee benefit" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 6,
        percentage_target: :employee_benefit,
        employee_benefit_type_percentage_target: :transportation_voucher,
        category_id: UUID.generate(),
        amount: Enum.random(100_00..1_000_00)
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               percentage: attrs[:percentage],
               percentage_target: attrs[:percentage_target],
               employee_benefit_type_percentage_target:
                 attrs[:employee_benefit_type_percentage_target],
               category_id: attrs[:category_id]
             }
    end

    test "missing attrs for percentage of employee benefit" do
      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 6,
        percentage_target: :employee_benefit,
        category_id: UUID.generate()
      }

      assert changeset = RecurringItemModel.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               employee_benefit_type_percentage_target: ["can't be blank"]
             }
    end

    test "inserts percentage of employee benefit" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        percentage: 6,
        percentage_target: :employee_benefit,
        employee_benefit_type_percentage_target: :transportation_voucher,
        category_id: category.id
      }

      assert {:ok, %RecurringItemModel{}} =
               attrs
               |> RecurringItemModel.create_changeset()
               |> Repo.insert()
    end

    test "description citext unique constraint" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      insert({:payslip_recurring_item_model, :fixed_amount},
        org: org,
        description: "RECURRING ITEM MODEL"
      )

      attrs = %{
        org_id: org.id,
        description: "recurring item model",
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: category.id
      }

      assert {:error, changeset} =
               attrs
               |> RecurringItemModel.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               description: ["has already been taken"]
             }
    end

    test "category assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> RecurringItemModel.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               category: ["does not exist"]
             }
    end
  end

  describe "update_changeset/2" do
    test "missing required description for fixed amount" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{description: nil}

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["can't be blank"]}
    end

    test "missing required amount for fixed amount" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{
        description: "New Description",
        amount: nil
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{amount: ["can't be blank"]}
    end

    test "valid attrs for fixed amount" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{
        description: Faker.Lorem.sentence(),
        amount: Enum.random(100_00..1_000_00)
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "drops non permitted attrs for fixed amount" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: false,
        amount: Enum.random(100_00..1_000_00),
        category_id: UUID.generate(),
        percentage: 6,
        percentage_target: :employee_benefit,
        employee_benefit_type_percentage_target: :transportation_voucher
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "string fields length greater than 255 chars" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{description: String.duplicate("a", 256)}

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{description: ["should be at most 255 character(s)"]}
    end

    test "updates fixed amount" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{
        description: Faker.Lorem.sentence(),
        amount: Enum.random(100_00..1_000_00)
      }

      assert {:ok, %RecurringItemModel{}} =
               rim
               |> RecurringItemModel.update_changeset(attrs)
               |> Repo.update()
    end

    test "valid attrs for percentage of employee salary" do
      rim = insert({:payslip_recurring_item_model, :percentage}, percentage: 10)

      attrs = %{
        description: Faker.Lorem.sentence(),
        percentage: 20,
        percentage_target: :employee_salary
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               percentage: attrs[:percentage]
             }
    end

    test "drops non permitted attrs for percentage of employee salary" do
      rim = insert({:payslip_recurring_item_model, :percentage}, percentage: 10)

      attrs = %{
        org_id: UUID.generate(),
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        percentage: 20,
        percentage_target: :employee_salary,
        category_id: UUID.generate(),
        amount: Enum.random(100_00..1_000_00),
        employee_benefit_type_percentage_target: :transportation_voucher
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               description: attrs[:description],
               percentage: attrs[:percentage]
             }
    end

    test "missing description for percentage of employee salary" do
      rim = insert({:payslip_recurring_item_model, :percentage})

      attrs = %{description: nil}

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["can't be blank"]
             }
    end

    test "missing attrs for percentage of employee salary" do
      rim = insert({:payslip_recurring_item_model, :percentage})

      attrs = %{
        description: "New Description",
        percentage: nil
      }

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               percentage: ["can't be blank"]
             }
    end

    test "validates percentage inclusion for less than 0" do
      rim = insert({:payslip_recurring_item_model, :percentage})

      attrs = %{percentage: -1}

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{percentage: ["is invalid"]}
    end

    test "validates percentage inclusion for more than 100" do
      rim = insert({:payslip_recurring_item_model, :percentage})

      attrs = %{percentage: 101}

      assert changeset = RecurringItemModel.update_changeset(rim, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{percentage: ["is invalid"]}
    end

    test "updates percentage of employee salary" do
      rim = insert({:payslip_recurring_item_model, :percentage})

      attrs = %{
        description: Faker.Lorem.sentence(),
        percentage: 20
      }

      assert {:ok, %RecurringItemModel{}} =
               rim
               |> RecurringItemModel.update_changeset(attrs)
               |> Repo.update()
    end
  end
end
