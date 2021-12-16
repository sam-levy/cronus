defmodule Sig.HR.PayslipTemplates.PayslipTemplateItemsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  @endpoint SigLive.Endpoint

  describe "create_payslip_item_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %PayslipTemplateItem{}, changes: %{type: :payslip_item}} =
               PayslipTemplateItems.create_payslip_item_change()
    end
  end

  describe "create_payslip_model_item_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %PayslipTemplateItem{}, changes: %{type: :payslip_item_model}} =
               PayslipTemplateItems.create_payslip_model_item_change()
    end
  end

  describe "create_payslip_model_item/2" do
    test "creates a payslip template item" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      attrs = %{payslip_recurring_item_model_id: rim.id}

      assert {:ok, %PayslipTemplateItem{}} =
               PayslipTemplateItems.create_payslip_model_item(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplateItem,
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
               PayslipTemplateItems.create_payslip_model_item(payslip_template, attrs)

      assert errors_on(changeset) == %{
               payslip_recurring_item_model: ["does not exist"]
             }
    end

    test "returns changeset errors" do
      payslip_template = insert(:payslip_template)

      assert {:error, changeset} =
               PayslipTemplateItems.create_payslip_model_item(payslip_template, %{})

      assert errors_on(changeset) == %{
               payslip_recurring_item_model_id: ["can't be blank"]
             }
    end
  end

  describe "create_payslip_item/2" do
    test "creates a payslip template item" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)
      payslip_category = insert(:payslip_category, org: org)

      attrs = %{
        payslip_category_id: payslip_category.id,
        amount: 100_00
      }

      assert {:ok, %PayslipTemplateItem{}} =
               PayslipTemplateItems.create_payslip_item(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplateItem,
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
               PayslipTemplateItems.create_payslip_item(payslip_template, attrs)

      assert errors_on(changeset) == %{
               payslip_category: ["does not exist"]
             }
    end

    test "returns changeset errors" do
      payslip_template = insert(:payslip_template)

      assert {:error, changeset} = PayslipTemplateItems.create_payslip_item(payslip_template, %{})

      assert errors_on(changeset) == %{
               payslip_category_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end
  end

  describe "list/1" do
    test "lists payslip template items from an payslip template ordered by category code" do
      org = insert(:org)
      %{id: payslip_template_id} = payslip_template = insert(:payslip_template, org: org)

      category_a = insert(:payslip_category, org: org, code: "A")
      category_b = insert(:payslip_category, org: org, code: "B")
      category_c = insert(:payslip_category, org: org, code: "C")
      category_d = insert(:payslip_category, org: org, code: "D")

      category_a_rim =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category_a)

      category_c_rim =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category_c)

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_c_rim
      )

      insert({:payslip_template_item, :payslip_item_model},
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_a_rim
      )

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: category_d
      )

      insert({:payslip_template_item, :payslip_item},
        org: org,
        payslip_template: payslip_template,
        payslip_category: category_b
      )

      _to_ignore = insert({:payslip_template_item, :payslip_item_model}, org: org)

      assert [
               %PayslipTemplateItem{
                 type: :payslip_item_model,
                 payslip_template_id: ^payslip_template_id,
                 payslip_recurring_item_model: %RecurringItemModel{category: %Category{code: "A"}}
               },
               %PayslipTemplateItem{
                 type: :payslip_item,
                 payslip_template_id: ^payslip_template_id,
                 payslip_category: %Category{code: "B"}
               },
               %PayslipTemplateItem{
                 type: :payslip_item_model,
                 payslip_template_id: ^payslip_template_id,
                 payslip_recurring_item_model: %RecurringItemModel{category: %Category{code: "C"}}
               },
               %PayslipTemplateItem{
                 type: :payslip_item,
                 payslip_template_id: ^payslip_template_id,
                 payslip_category: %Category{code: "D"}
               }
             ] = PayslipTemplateItems.list(payslip_template)
    end

    test "when payslip templates has no items" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      assert PayslipTemplateItems.list(payslip_template) == []
    end
  end

  describe "list_by/1" do
    test "lists payslip template items by attrs" do
      org = insert(:org)
      %{id: payslip_template_id} = payslip_template = insert(:payslip_template, org: org)

      category_b = insert(:payslip_category, org: org, code: "B")
      category_a = insert(:payslip_category, org: org, code: "A")

      category_b_rim =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category_b)

      category_a_rim =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category_a)

      insert(:payslip_template_item,
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_b_rim
      )

      insert(:payslip_template_item,
        org: org,
        payslip_template: payslip_template,
        payslip_recurring_item_model: category_a_rim
      )

      _to_ignore = insert(:payslip_template_item, org: org)

      assert [
               %PayslipTemplateItem{
                 payslip_template_id: ^payslip_template_id,
                 payslip_recurring_item_model: %RecurringItemModel{category: %Category{code: "A"}}
               },
               %PayslipTemplateItem{
                 payslip_template_id: ^payslip_template_id,
                 payslip_recurring_item_model: %RecurringItemModel{category: %Category{code: "B"}}
               }
             ] =
               PayslipTemplateItems.list_by(
                 org_id: org.id,
                 payslip_template_id: payslip_template.id
               )
    end

    test "when payslip templates has no items" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      assert PayslipTemplateItems.list_by(
               org_id: org.id,
               payslip_template_id: payslip_template.id
             ) == []
    end
  end

  describe "delete/1" do
    test "deletes a payslip template item" do
      item = insert({:payslip_template_item, :payslip_item_model})

      assert {:ok, %PayslipTemplateItem{}} = PayslipTemplateItems.delete(item)

      refute Repo.get_by(PayslipTemplateItem,
               org_id: item.org_id,
               payslip_template_id: item.payslip_template_id,
               payslip_recurring_item_model_id: item.payslip_recurring_item_model_id
             )
    end
  end

  describe "subscribe_to_payslip_template_items/1" do
    test "subscribes to the payslip templates topic" do
      payslip_template = insert(:payslip_template)
      topic = "payslip_template_id:" <> payslip_template.id <> ":payslip_template_items"

      assert PayslipTemplateItems.subscribe_to_payslip_template_items(payslip_template) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:new_payslip_template_items, :payslip_template_item}
      )

      assert_receive {:new_payslip_template_items, :payslip_template_item}
    end
  end

  describe "broadcast_new_payslip_template_item/1" do
    test "broadcasts a new payslip template_item from a template with preloads" do
      org = insert(:org)
      %{id: payslip_template_id} = payslip_template = insert(:payslip_template, org: org)

      payslip_template_item =
        insert({:payslip_template_item, :payslip_item_model},
          payslip_template: payslip_template,
          org: org
        )

      topic = "payslip_template_id:" <> payslip_template.id <> ":payslip_template_items"

      @endpoint.subscribe(topic)

      assert PayslipTemplateItems.broadcast_new_payslip_template_item(payslip_template_item) ==
               :ok

      assert_receive {:new_payslip_template_item, received_payslip_template_item}

      assert %PayslipTemplateItem{
               payslip_template_id: ^payslip_template_id,
               payslip_recurring_item_model: %RecurringItemModel{category: %Category{}}
             } = received_payslip_template_item

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_payslip_template_item/1" do
    test "broadcasts a deleted payslip template_item from a template" do
      org = insert(:org)
      payslip_template = insert(:payslip_template, org: org)

      payslip_template_item =
        insert({:payslip_template_item, :payslip_item_model},
          payslip_template: payslip_template,
          org: org
        )

      topic = "payslip_template_id:" <> payslip_template.id <> ":payslip_template_items"

      @endpoint.subscribe(topic)

      assert PayslipTemplateItems.broadcast_deleted_payslip_template_item(payslip_template_item) ==
               :ok

      assert_receive {:deleted_payslip_template_item, received_payslip_template_item}

      assert received_payslip_template_item.payslip_template_id ==
               payslip_template_item.payslip_template_id

      @endpoint.unsubscribe(topic)
    end
  end
end
