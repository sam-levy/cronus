defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.CreatorTest do
  use Sig.DataCase, async: true

  alias Sig.HR.PayslipTemplates.PayslipTemplateItems
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  describe "create_payslip_template_item/2" do
    test "creates a payslip template item" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      category_rim =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          category: payslip_category
        )

      # Ignores repeated category code when item belongs to another template
      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_recurring_item_model: category_rim
      )

      attrs = %{
        payslip_category_id: payslip_category.id,
        amount: 100_00
      }

      assert {:ok, %PayslipTemplateItem{}} =
               PayslipTemplateItems.create_payslip_template_item(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               payslip_template_id: payslip_template.id,
               payslip_category_id: attrs[:payslip_category_id],
               amount: attrs[:amount],
               type: :payslip_item
             )
    end

    test "existing item with the same category code" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      category_rim =
        insert({:payslip_recurring_item_model, :fixed_amount},
          org: org,
          category: payslip_category
        )

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_rim
      )

      attrs = %{
        payslip_category_id: payslip_category.id,
        amount: 100_00
      }

      assert PayslipTemplateItems.create_payslip_template_item(payslip_template, attrs) ==
               {:error, "Já exsite um item com o mesmo código neste modelo de holerite"}

      refute Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               payslip_template_id: payslip_template.id,
               payslip_category_id: attrs[:payslip_category_id],
               amount: attrs[:amount],
               type: :payslip_item
             )
    end

    test "when category belongs to another org" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category)

      attrs = %{
        payslip_category_id: payslip_category.id,
        amount: 100_00
      }

      assert {:error, changeset} =
               PayslipTemplateItems.create_payslip_template_item(payslip_template, attrs)

      assert errors_on(changeset) == %{
               payslip_category: ["does not exist"]
             }
    end

    test "returns changeset errors" do
      payslip_template = insert(:payslip_template)

      assert {:error, changeset} =
               PayslipTemplateItems.create_payslip_template_item(payslip_template, %{})

      assert errors_on(changeset) == %{
               payslip_category_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end
  end

  describe "create_payslip_template_model_item/2" do
    test "creates a payslip template item" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      # Ignores repeated category code when item belongs to another template
      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_category: rim.category
      )

      attrs = %{payslip_recurring_item_model_id: rim.id}

      assert {:ok, %PayslipTemplateItem{}} =
               PayslipTemplateItems.create_payslip_template_model_item(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               payslip_template_id: payslip_template.id,
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id],
               type: :payslip_item_model
             )
    end

    test "existing item with the same category code" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: rim.category
      )

      attrs = %{payslip_recurring_item_model_id: rim.id}

      assert PayslipTemplateItems.create_payslip_template_model_item(payslip_template, attrs) ==
               {:error, "Já exsite um item com o mesmo código neste modelo de holerite"}

      refute Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               payslip_template_id: payslip_template.id,
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id],
               type: :payslip_item_model
             )
    end

    test "when recurring item model belongs to another org" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{payslip_recurring_item_model_id: rim.id}

      assert {:error, changeset} =
               PayslipTemplateItems.create_payslip_template_model_item(payslip_template, attrs)

      assert errors_on(changeset) == %{
               payslip_recurring_item_model: ["does not exist"]
             }
    end

    test "returns changeset errors" do
      payslip_template = insert(:payslip_template)

      assert {:error, changeset} =
               PayslipTemplateItems.create_payslip_template_model_item(payslip_template, %{})

      assert errors_on(changeset) == %{
               payslip_recurring_item_model_id: ["can't be blank"]
             }
    end
  end
end
