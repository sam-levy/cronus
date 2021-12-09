defmodule Sig.HR.Registrations.RecurringPayslipItemsTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem

  @endpoint SigLive.Endpoint

  describe "create_change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(:payslip_item)

      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(%{}, :payslip_item)

      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(:payslip_item_model)

      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(%{}, :payslip_item_model)

      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(:outside_item)

      assert %Ecto.Changeset{data: %RecurringPayslipItem{}} =
               RecurringPayslipItems.create_change(%{}, :outside_item)
    end
  end

  describe "list_by/2" do
    test "lists recurring payslip items by recurring item model" do
      org = insert(:org)
      rim = insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      rpi =
        insert_list(2, {:employee_registration_recurring_payslip_item, :payslip_item_model},
          org: org,
          payslip_recurring_item_model: rim
        )

      assert [%RecurringPayslipItem{}, %RecurringPayslipItem{}] =
               RecurringPayslipItems.list_by(rim)
    end

    test "when recurring item model has no recurring payslilp items" do
      org = insert(:org)
      insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

      assert RecurringPayslipItems.list_by(rim) == []
    end
  end

  describe "create/3" do
    test "creates a recurring payslip_item" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org, entry_type: :credit)

      attrs = %{
        payslip_category_id: category.id,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, %RecurringPayslipItem{id: id}} =
               RecurringPayslipItems.create(registration, attrs, :payslip_item)

      assert Repo.get_by(RecurringPayslipItem,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item,
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: attrs[:item_amount]
             )
    end

    test "creates a recurring payslip_item_model" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org, entry_type: :credit)

      payslip_recurring_item_model =
        insert({:payslip_recurring_item_model, :fixed_amount}, org: org, category: category)

      attrs = %{
        payslip_recurring_item_model_id: payslip_recurring_item_model.id
      }

      assert {:ok, %RecurringPayslipItem{id: id}} =
               RecurringPayslipItems.create(registration, attrs, :payslip_item_model)

      assert Repo.get_by(RecurringPayslipItem,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item_model,
               payslip_recurring_item_model_id: attrs[:payslip_recurring_item_model_id]
             )
    end

    test "creates a recurring outside_item" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      attrs = %{
        item_amount: Enum.random(100_00..5_000_00),
        outside_item_description: Faker.Lorem.sentence(),
        outside_item_entry_type: :credit,
        outside_item_is_payment_advance: false
      }

      assert {:ok, %RecurringPayslipItem{id: id}} =
               RecurringPayslipItems.create(registration, attrs, :outside_item)

      assert Repo.get_by(RecurringPayslipItem,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: :outside_item,
               item_amount: attrs[:item_amount],
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: attrs[:outside_item_is_payment_advance]
             )
    end

    test "when there is an existing recurring item with the same description" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      category =
        insert(:payslip_category, org: org, entry_type: :credit, description: "DESCRIPTION")

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration,
        category: category,
        item_amount: 100_00
      )

      attrs = %{
        item_amount: 50_00,
        outside_item_description: "DESCRIPTION",
        outside_item_entry_type: :credit,
        outside_item_is_payment_advance: false
      }

      assert RecurringPayslipItems.create(registration, attrs, :outside_item) ==
               {:error, "has already been taken"}

      refute Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               type: :outside_item,
               item_amount: attrs[:item_amount],
               outside_item_description: attrs[:outside_item_description],
               outside_item_entry_type: attrs[:outside_item_entry_type],
               outside_item_is_payment_advance: attrs[:outside_item_is_payment_advance]
             )
    end

    test "return changeset errors" do
      registration = insert(:employee_registration)

      attrs = %{
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert {:error, changeset} =
               RecurringPayslipItems.create(registration, attrs, :payslip_item)

      assert errors_on(changeset) == %{
               payslip_category_id: ["can't be blank"]
             }
    end

    test "when the first payslip_item is from a debit category" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)
      category = insert(:payslip_category, org: org, entry_type: :debit)

      attrs = %{
        payslip_category_id: category.id,
        item_amount: Enum.random(100_00..5_000_00)
      }

      assert RecurringPayslipItems.create(registration, attrs, :payslip_item) ==
               {:error, "Recurring payslip items amount sum can't be negative"}

      refute Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item,
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: attrs[:item_amount]
             )
    end

    test "when the new payslip_item brings the amount sum to negative" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :credit,
        item_amount: 50_00
      )

      category = insert(:payslip_category, org: org, entry_type: :debit)

      attrs = %{
        payslip_category_id: category.id,
        item_amount: 100_00
      }

      assert RecurringPayslipItems.create(registration, attrs, :payslip_item) ==
               {:error, "Recurring payslip items amount sum can't be negative"}

      refute Repo.get_by(RecurringPayslipItem,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item,
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: attrs[:item_amount]
             )
    end

    test "when the new payslip_item brings the amount sum to positive" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :debit,
        item_amount: 50_00
      )

      category = insert(:payslip_category, org: org, entry_type: :credit)

      attrs = %{
        payslip_category_id: category.id,
        item_amount: 100_00
      }

      assert {:ok, %RecurringPayslipItem{id: id}} =
               RecurringPayslipItems.create(registration, attrs, :payslip_item)

      assert Repo.get_by(RecurringPayslipItem,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item,
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: attrs[:item_amount]
             )
    end

    test "when the new payslip_item makes the amount sum less negative" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :debit,
        item_amount: 100_00
      )

      category = insert(:payslip_category, org: org, entry_type: :credit)

      attrs = %{
        payslip_category_id: category.id,
        item_amount: 50_00
      }

      assert {:ok, %RecurringPayslipItem{id: id}} =
               RecurringPayslipItems.create(registration, attrs, :payslip_item)

      assert Repo.get_by(RecurringPayslipItem,
               id: id,
               org_id: org.id,
               registration_id: registration.id,
               type: :payslip_item,
               payslip_category_id: attrs[:payslip_category_id],
               item_amount: attrs[:item_amount]
             )
    end
  end

  describe "delete/2" do
    test "deletes a recurring payslip item" do
      %{id: id} = item = insert({:employee_registration_recurring_payslip_item, :payslip_item})

      assert {:ok, %RecurringPayslipItem{id: ^id}} =
               RecurringPayslipItems.delete(item.registration, item.id)

      refute Repo.get_by(RecurringPayslipItem, id: id, org_id: item.org_id)
    end

    test "when the deletion brings the amount sum to negative" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :debit,
        item_amount: 50_00
      )

      category = insert(:payslip_category, org: org, entry_type: :credit)

      %{id: id} =
        item =
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          category: category,
          item_amount: 100_00
        )

      assert RecurringPayslipItems.delete(item.registration, item.id) ==
               {:error, "Recurring payslip items amount sum can't be negative"}

      assert Repo.get_by(RecurringPayslipItem, id: id, org_id: org.id)
    end

    test "when the deletion makes the amount sum less negative" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :debit,
        item_amount: 100_00
      )

      category = insert(:payslip_category, org: org, entry_type: :debit)

      %{id: id} =
        item =
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          category: category,
          item_amount: 50_00
        )

      assert {:ok, %RecurringPayslipItem{id: ^id}} =
               RecurringPayslipItems.delete(item.registration, item.id)

      refute Repo.get_by(RecurringPayslipItem, id: id, org_id: org.id)
    end

    test "when the deletion brings the amount sum to positive" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :outside_item},
        org: org,
        registration: registration,
        outside_item_entry_type: :credit,
        item_amount: 50_00
      )

      category = insert(:payslip_category, org: org, entry_type: :debit)

      %{id: id} =
        item =
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration,
          category: category,
          item_amount: 100_00
        )

      assert {:ok, %RecurringPayslipItem{id: ^id}} =
               RecurringPayslipItems.delete(item.registration, item.id)

      refute Repo.get_by(RecurringPayslipItem, id: id, org_id: org.id)
    end

    test "when item doesn't belong to registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      item =
        insert({:employee_registration_recurring_payslip_item, :payslip_item},
          org: org,
          registration: registration
        )

      other_registration = insert(:employee_registration, org: org)

      assert RecurringPayslipItems.delete(other_registration, item.id) == {:error, :not_found}

      assert Repo.get_by(RecurringPayslipItem, id: item.id, org_id: org.id)
    end

    test "when item doesn't exist" do
      registration = insert(:employee_registration)

      assert RecurringPayslipItems.delete(registration, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "subscribe_to_registration_recurring_payslip_items/1" do
    test "subscribes to registration recurring_payslip_items topic" do
      registration = insert(:employee_registration)
      topic = "registration_id:" <> registration.id <> ":recurring_payslip_items"

      assert RecurringPayslipItems.subscribe_to_registration_recurring_payslip_items(registration) ==
               :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:updated_registration_recurring_payslip_items, :recurring_payslip_items}
      )

      assert_receive {:updated_registration_recurring_payslip_items, :recurring_payslip_items}
    end
  end

  describe "broadcast_registration_recurring_payslip_items/1" do
    test "broadcasts recurring_payslip_items from a registration" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration
      )

      insert({:employee_registration_recurring_payslip_item, :payslip_item},
        org: org,
        registration: registration
      )

      insert({:employee_registration_recurring_payslip_item, :payslip_item}, org: org)

      topic = "registration_id:" <> registration.id <> ":recurring_payslip_items"

      @endpoint.subscribe(topic)

      assert RecurringPayslipItems.broadcast_registration_recurring_payslip_items(registration) ==
               :ok

      assert_receive {:updated_registration_recurring_payslip_items,
                      received_recurring_payslip_items}

      assert Enum.count(received_recurring_payslip_items) == 2

      Enum.each(received_recurring_payslip_items, fn recurring_payslip_item ->
        assert recurring_payslip_item.org_id == org.id
        assert recurring_payslip_item.registration_id == registration.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
