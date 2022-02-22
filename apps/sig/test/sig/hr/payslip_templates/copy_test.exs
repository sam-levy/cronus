defmodule Sig.HR.PayslipTemplates.CopyTest do
  use Sig.DataCase, async: true

  alias Sig.HR.PayslipTemplates.Copy
  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  describe "call/1" do
    test "copy a payslip template and its payslip template items" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org, name: "Original")
      category = insert(:payslip_category, org: org, code: "A")

      category_rim =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category)

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: category
      )

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_rim
      )

      _to_ignore = insert({:payslip_template_item, :payslip_item_model}, org: org)

      attrs = %{
        name: "Copy"
      }

      assert {:ok, %PayslipTemplate{} = payslip_template_copy} =
               Copy.call(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplate,
               org_id: org.id,
               id: payslip_template_copy.id,
               name: "Copy"
             )

      assert PayslipTemplateItem
             |> where(payslip_template_id: ^payslip_template_copy.id)
             |> Repo.aggregate(:count) == 2

      assert Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               type: :payslip_item,
               payslip_template_id: payslip_template_copy.id,
               payslip_category_id: category.id
             )

      assert Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               type: :payslip_item_model,
               payslip_template_id: payslip_template_copy.id,
               payslip_recurring_item_model_id: category_rim.id
             )
    end

    test "return changeset errors" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org, name: "Original")
      category = insert(:payslip_category, org: org, code: "A")

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: category
      )

      assert {:error, changeset} = Copy.call(payslip_template, %{})

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }
    end

    test "Creates a payslip template with no items when the original has no items" do
      payslip_template = insert(:payslip_template, name: "Original")

      attrs = %{
        name: "Copy"
      }

      assert {:ok, %PayslipTemplate{} = payslip_template_copy} =
               Copy.call(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplate,
               org_id: payslip_template_copy.org_id,
               id: payslip_template_copy.id,
               name: "Copy"
             )

      assert PayslipTemplateItem
             |> where(payslip_template_id: ^payslip_template_copy.id)
             |> Repo.aggregate(:count) == 0
    end
  end
end
