defmodule Sig.HR.Payslips.RecurringItemModelsTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.RecurringItemModels
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %RecurringItemModel{}} = RecurringItemModels.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %RecurringItemModel{}} =
               RecurringItemModels.update_change(%RecurringItemModel{}, %{})

      assert %Ecto.Changeset{data: %RecurringItemModel{}} =
               RecurringItemModels.update_change(%RecurringItemModel{})
    end
  end

  describe "list/1" do
    test "lists payslips recurring item models from an organization with categories" do
      %{id: org_id} = org = insert(:org)

      category_2 = insert(:payslip_category, org: org, code: "2")
      category_1 = insert(:payslip_category, org: org, code: "1")

      insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category_2)
      insert({:payslip_recurring_item_model, :percentage}, org: org, category: category_1)
      _to_ignore = insert({:payslip_recurring_item_model, :fixed_amount})

      assert [
               %RecurringItemModel{org_id: ^org_id, category: %Category{code: "1"}},
               %RecurringItemModel{org_id: ^org_id, category: %Category{code: "2"}}
             ] = RecurringItemModels.list(org)
    end

    test "when org has no recurring item" do
      org = insert(:org)

      assert RecurringItemModels.list(org) == []
    end
  end

  describe "list_by/1" do
    test "lists recurring item models by category" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      insert_list(2, {:payslip_recurring_item_model, :fixed_amount},
        org: org,
        category: category
      )

      _to_ignore = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      assert [%RecurringItemModel{}, %RecurringItemModel{}] =
               RecurringItemModels.list_by(category)
    end

    test "when category has no recurring payslilp items" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      assert RecurringItemModels.list_by(category) == []
    end
  end

  describe "count_by/1" do
    test "counts recurring item models by category" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      insert_list(2, {:payslip_recurring_item_model, :fixed_amount},
        org: org,
        category: category
      )

      _to_ignore = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      assert RecurringItemModels.count_by(category) == 2
    end

    test "when category has no recurring payslilp items" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      assert RecurringItemModels.count_by(category) == 0
    end
  end

  describe "create/2" do
    test "creates a recurring item model" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      attrs = %{
        description: Faker.Lorem.sentence(),
        is_fixed_amount: true,
        amount: Enum.random(100_00..1_000_00),
        category_id: category.id
      }

      assert {:ok, %RecurringItemModel{id: id}} = RecurringItemModels.create(org, attrs)

      assert Repo.get_by(RecurringItemModel,
               id: id,
               org_id: org.id,
               description: attrs[:description],
               is_fixed_amount: attrs[:is_fixed_amount],
               amount: attrs[:amount],
               category_id: attrs[:category_id]
             )
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = RecurringItemModels.create(org, %{})

      assert errors_on(changeset) == %{
               category_id: ["can't be blank"],
               description: ["can't be blank"],
               is_fixed_amount: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a recurring item model" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{description: "New Description"}

      assert {:ok, _return} = RecurringItemModels.update(rim, attrs)

      assert Repo.get_by(RecurringItemModel,
               id: rim.id,
               org_id: rim.org_id,
               description: attrs[:description]
             )
    end

    test "returns changeset errors" do
      rim = insert({:payslip_recurring_item_model, :fixed_amount})

      attrs = %{description: nil}

      assert {:error, changeset} = RecurringItemModels.update(rim, attrs)

      assert errors_on(changeset) == %{
               description: ["can't be blank"]
             }
    end
  end

  describe "get/3" do
    test "returns a recurring item model" do
      org = insert(:org)
      %{id: id} = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      assert %RecurringItemModel{id: ^id} = RecurringItemModels.get(org, id)
    end

    test "when recurring item model doesn't belongs to org" do
      org = insert(:org)
      %{id: id} = insert({:payslip_recurring_item_model, :fixed_amount})

      assert RecurringItemModels.get(org, id) == nil
    end

    test "when recurring item model doesn't exist" do
      org = insert(:org)

      assert RecurringItemModels.get(org, UUID.generate()) == nil
    end
  end

  describe "get_by/3" do
    test "returns a recurring item model" do
      org = insert(:org)
      category = insert(:payslip_category, org: org)

      %{id: id} =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category)

      assert %RecurringItemModel{id: ^id} = RecurringItemModels.get_by(org_id: org.id, id: id)
    end

    test "when recurring item model doesn't exist" do
      org = insert(:org)

      assert RecurringItemModels.get_by(org_id: org.id, id: UUID.generate()) == nil
    end
  end

  describe "delete/1" do
    test "deletes a recurring item model" do
      %{id: id} = rim = insert({:payslip_recurring_item_model, :fixed_amount})

      assert {:ok, %RecurringItemModel{id: ^id}} = RecurringItemModels.delete(rim)
    end

    test "when the recurring item model is associated to a recurring payslip item" do
      org = insert(:org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      insert({:employee_registration_recurring_payslip_item, :payslip_item_model},
        org: org,
        payslip_recurring_item_model: rim
      )

      assert RecurringItemModels.delete(rim) ==
               {:error, "Existem holerites modelo usando este modelo de item"}
    end
  end

  describe "subscribe_to_payslip_recurring_item_models/1" do
    test "subscribes to payslip recurring item models topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":payslip_recurring_item_models"

      assert RecurringItemModels.subscribe_to_payslip_recurring_item_models(org) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:new_payslip_recurring_item_model, :payslip_recurring_item_model}
      )

      assert_receive {:new_payslip_recurring_item_model, :payslip_recurring_item_model}
    end
  end

  describe "broadcast_new_payslip_recurring_item_model/1" do
    test "broadcasts recurring item models from a org" do
      org = insert(:org)

      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      topic = "org_id:" <> org.id <> ":payslip_recurring_item_models"

      @endpoint.subscribe(topic)

      assert RecurringItemModels.broadcast_new_payslip_recurring_item_model(rim) == :ok

      assert_receive {:new_payslip_recurring_item_model, received_rim}

      assert received_rim.id == rim.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_payslip_recurring_item_model/1" do
    test "broadcasts recurring item models from a org" do
      org = insert(:org)

      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      topic = "org_id:" <> org.id <> ":payslip_recurring_item_models"

      @endpoint.subscribe(topic)

      assert RecurringItemModels.broadcast_updated_payslip_recurring_item_model(rim) == :ok

      assert_receive {:updated_payslip_recurring_item_model, received_rim}

      assert received_rim.id == rim.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_payslip_recurring_item_model/1" do
    test "broadcasts recurring item models from a org" do
      org = insert(:org)

      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      topic = "org_id:" <> org.id <> ":payslip_recurring_item_models"

      @endpoint.subscribe(topic)

      assert RecurringItemModels.broadcast_deleted_payslip_recurring_item_model(rim) == :ok

      assert_receive {:deleted_payslip_recurring_item_model, received_rim}

      assert received_rim.id == rim.id

      @endpoint.unsubscribe(topic)
    end
  end
end
