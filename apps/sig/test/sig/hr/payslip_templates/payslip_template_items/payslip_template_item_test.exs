defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItemTest do
  use Sig.DataCase, async: true

  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  describe "payslip_templates table base constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_template_items\" violates not-null constraint/,
                   fn -> Repo.insert!(item) end
    end

    test "org_id foreign_key_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        org_id: UUID.generate(),
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_template_id not_null_violation" do
      org = insert(:org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"payslip_template_id\" of relation \"payslip_template_items\" violates not-null constraint/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_template_id foreign_key_constraint" do
      org = insert(:org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: UUID.generate(),
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_payslip_template_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end
  end

  describe "payslip_templates table `payslip_item_model` type conditional constraints" do
    test "payslip_recurring_item_model_id not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_recurring_item_model_id foreign_key_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: UUID.generate(),
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_payslip_recurring_item_model_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_template_items_model_unique unique_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      _existing_payslip_template_item =
        insert({:payslip_template_item, :payslip_item_model},
          org: org,
          payslip_template: payslip_template,
          payslip_recurring_item_model: rim
        )

      # Allow same payslip_recurring_item_model for different payslip template
      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_recurring_item_model: rim
      )

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_model_unique \(unique_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "sucess" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id,
        type: :payslip_item_model
      }

      assert {:ok, %PayslipTemplateItem{}} = Repo.insert(item)
    end
  end

  describe "payslip_templates table `payslip_item` type conditional constraints" do
    test "payslip_category_id not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        amount: 100_00,
        type: :payslip_item
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_category_id foreign_key_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: UUID.generate(),
        amount: 100_00,
        type: :payslip_item
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_payslip_category_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "amount not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: payslip_category.id,
        type: :payslip_item
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_conditional \(check_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_template_items_positive_amount check_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: payslip_category.id,
        type: :payslip_item,
        amount: -100_00
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_positive_amount \(check_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_template_items_category_unique unique_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      _existing_payslip_template_item =
        insert({:payslip_template_item, :payslip_item},
          org: org,
          payslip_template: payslip_template,
          payslip_category: payslip_category
        )

      # Allow same category for different payslip template
      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_category: payslip_category
      )

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: payslip_category.id,
        type: :payslip_item,
        amount: 100_00
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_category_unique \(unique_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "success" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: payslip_category.id,
        type: :payslip_item,
        amount: 100_00
      }

      assert {:ok, %PayslipTemplateItem{}} = Repo.insert(item)
    end
  end

  describe "create_payslip_template_model_item_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_model_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               payslip_template_id: attrs[:payslip_template_id],
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id],
               type: :payslip_item_model
             }
    end

    test "missing required attrs" do
      assert changeset = PayslipTemplateItem.create_payslip_template_model_item_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               payslip_template_id: ["can't be blank"],
               payslip_recurring_item_model_id: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_recurring_item_model_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        amount: 100_00
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_model_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               payslip_template_id: attrs[:payslip_template_id],
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id],
               type: :payslip_item_model
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        payslip_template_id: :invalid,
        payslip_recurring_item_model_id: :invalid
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_model_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               payslip_template_id: ["is invalid"],
               payslip_recurring_item_model_id: ["is invalid"]
             }
    end

    test "payslip_recurring_item_model assoc constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      attrs = %{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> PayslipTemplateItem.create_payslip_template_model_item_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_recurring_item_model: ["does not exist"]
             }
    end

    test "payslip_recurring_item_model unique constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: rim
      )

      attrs = %{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id
      }

      assert {:error, changeset} =
               attrs
               |> PayslipTemplateItem.create_payslip_template_model_item_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_recurring_item_model_id: ["has already been taken"]
             }
    end
  end

  describe "create_payslip_template_item_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        amount: 100_00
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               payslip_template_id: attrs[:payslip_template_id],
               payslip_category_id: attrs[:payslip_category_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               type: :payslip_item
             }
    end

    test "missing required attrs" do
      assert changeset = PayslipTemplateItem.create_payslip_template_item_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               payslip_template_id: ["can't be blank"],
               payslip_category_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        amount: 100_00,
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_item_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               payslip_template_id: attrs[:payslip_template_id],
               payslip_category_id: attrs[:payslip_category_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL},
               type: :payslip_item
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        payslip_template_id: :invalid,
        payslip_category_id: :invalid,
        amount: :invalid
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               payslip_template_id: ["is invalid"],
               payslip_category_id: ["is invalid"],
               amount: ["is invalid"]
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_category_id: UUID.generate(),
        amount: -100_00
      }

      assert changeset = PayslipTemplateItem.create_payslip_template_item_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "payslip_category assoc constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      attrs = %{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: UUID.generate(),
        amount: 100_00
      }

      assert {:error, changeset} =
               attrs
               |> PayslipTemplateItem.create_payslip_template_item_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_category: ["does not exist"]
             }
    end

    test "payslip_category unique constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: payslip_category
      )

      attrs = %{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_category_id: payslip_category.id,
        amount: 100_00
      }

      assert {:error, changeset} =
               attrs
               |> PayslipTemplateItem.create_payslip_template_item_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_category_id: ["has already been taken"]
             }
    end
  end
end
