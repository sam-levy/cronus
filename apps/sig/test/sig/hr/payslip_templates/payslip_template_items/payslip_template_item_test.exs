defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItemTest do
  use Sig.DataCase

  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  describe "payslip_templates table constraints" do
    test "org_id not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      item = %PayslipTemplateItem{
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: rim.id
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
        payslip_recurring_item_model_id: rim.id
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
        payslip_recurring_item_model_id: rim.id
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
        payslip_recurring_item_model_id: rim.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_payslip_template_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_recurring_item_model_id not_null_violation" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"payslip_recurring_item_model_id\" of relation \"payslip_template_items\" violates not-null constraint/,
                   fn -> Repo.insert!(item) end
    end

    test "payslip_recurring_item_model_id foreign_key_constraint" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      item = %PayslipTemplateItem{
        org_id: org.id,
        payslip_template_id: payslip_template.id,
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_template_items_payslip_recurring_item_model_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(item) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        payslip_template_id: UUID.generate(),
        payslip_recurring_item_model_id: UUID.generate()
      }

      assert changeset = PayslipTemplateItem.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               payslip_template_id: attrs[:payslip_template_id],
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id]
             }
    end

    test "missing required attrs" do
      assert changeset = PayslipTemplateItem.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               payslip_template_id: ["can't be blank"],
               payslip_recurring_item_model_id: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        payslip_template_id: :invalid,
        payslip_recurring_item_model_id: :invalid
      }

      assert changeset = PayslipTemplateItem.create_changeset(attrs)

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
               |> PayslipTemplateItem.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               payslip_recurring_item_model: ["does not exist"]
             }
    end
  end
end
