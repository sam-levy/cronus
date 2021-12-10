defmodule Sig.HR.Payslips.CategoriesTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.Categories.Category

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Category{}} = Categories.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Category{}} = Categories.update_change(%Category{}, %{})
      assert %Ecto.Changeset{data: %Category{}} = Categories.update_change(%Category{})
    end
  end

  describe "list/1" do
    test "lists payslips categories from an organization" do
      org = insert(:org)

      insert_list(2, :payslip_category, org: org)
      _to_ignore = insert(:payslip_category)

      assert return = Categories.list(org.id)

      assert Enum.count(return) == 2

      assert Enum.all?(return, &(&1.org_id == org.id))
    end

    test "when org has no category" do
      org = insert(:org)

      assert Categories.list(org.id) == []
    end
  end

  describe "get/2" do
    test "returns a category" do
      org = insert(:org)
      %{id: id} = insert(:payslip_category, org: org)

      assert %Category{id: ^id} = Categories.get(org.id, id)
    end

    test "when category belongs to another org" do
      org = insert(:org)
      another_org = insert(:org)
      %{id: id} = insert(:payslip_category, org: another_org)

      assert Categories.get(org.id, id) == nil
    end

    test "when category doesn't exist" do
      org = insert(:org)

      assert Categories.get(org.id, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "returns a category" do
      org = insert(:org)
      %{id: id} = insert(:payslip_category, org: org)

      assert {:ok, %Category{id: ^id}} = Categories.fetch(org.id, id)
    end

    test "when category belongs to another org" do
      org = insert(:org)
      another_org = insert(:org)
      %{id: id} = insert(:payslip_category, org: another_org)

      assert Categories.fetch(org.id, id) == {:error, :not_found}
    end

    test "when category doesn't exist" do
      org = insert(:org)

      assert Categories.fetch(org.id, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "create/2" do
    test "creates a payslip category" do
      org = insert(:org)

      attrs = %{
        code: random_string_number(),
        description: Faker.Lorem.sentence(),
        entry_type: :credit,
        is_payment_advance: false
      }

      assert {:ok, %Category{id: id}} = Categories.create(org, attrs)

      assert Repo.get_by(Category,
               id: id,
               org_id: org.id,
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               is_payment_advance: attrs[:is_payment_advance]
             )
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = Categories.create(org, %{})

      assert errors_on(changeset) == %{
               code: ["can't be blank"],
               description: ["can't be blank"],
               entry_type: ["can't be blank"],
               is_payment_advance: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a payslip category" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{
        code: "New Code",
        description: "New Description",
        entry_type: :credit,
        is_payment_advance: false
      }

      assert {:ok, %Category{}} = Categories.update(category, attrs)

      assert Repo.get_by(Category,
               code: attrs[:code],
               description: attrs[:description],
               entry_type: attrs[:entry_type],
               is_payment_advance: attrs[:is_payment_advance]
             )
    end

    test "returns changeset errors" do
      category = insert(:payslip_category, entry_type: :debit, is_payment_advance: true)

      attrs = %{code: nil}

      assert {:error, changeset} = Categories.update(category, attrs)

      assert errors_on(changeset) == %{
               code: ["can't be blank"]
             }
    end
  end

  describe "broadcast_new_payslip_category/1" do
    test "broadcasts a new payslip category from an org" do
      org = insert(:org)

      payslip_category = insert(:payslip_category, org: org)

      topic = "org_id:" <> org.id <> ":payslip_categories"

      @endpoint.subscribe(topic)

      assert Categories.broadcast_new_payslip_category(payslip_category) == :ok

      assert_receive {:new_payslip_category, received_payslip_category}

      assert received_payslip_category.id == payslip_category.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_payslip_category/1" do
    test "broadcasts an updated payslip category from an org" do
      org = insert(:org)

      payslip_category = insert(:payslip_category, org: org)

      topic = "org_id:" <> org.id <> ":payslip_categories"

      @endpoint.subscribe(topic)

      assert Categories.broadcast_updated_payslip_category(payslip_category) == :ok

      assert_receive {:updated_payslip_category, received_payslip_category}

      assert received_payslip_category.id == payslip_category.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_payslip_category/1" do
    test "broadcasts a deleted payslip category from an org" do
      org = insert(:org)

      payslip_category = insert(:payslip_category, org: org)

      topic = "org_id:" <> org.id <> ":payslip_categories"

      @endpoint.subscribe(topic)

      assert Categories.broadcast_deleted_payslip_category(payslip_category) == :ok

      assert_receive {:deleted_payslip_category, received_payslip_category}

      assert received_payslip_category.id == payslip_category.id

      @endpoint.unsubscribe(topic)
    end
  end
end
