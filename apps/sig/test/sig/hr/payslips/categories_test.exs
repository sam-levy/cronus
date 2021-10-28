defmodule Sig.HR.Payslips.CategoriesTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.Categories.Category

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
end
