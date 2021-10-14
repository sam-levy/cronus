defmodule Sig.HR.Payslips.CategoriesTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Categories

  describe "list/1" do
    test "lists payslips categories from an organization" do
      org = insert(:org)

      insert_list(2, :payslip_category, org: org)
      _to_ignore = insert(:payslip_category)

      assert return = Categories.list(org)

      assert Enum.count(return) == 2

      assert Enum.all?(return, & &1.org_id == org.id)
    end

    test "when org has no category" do
      org = insert(:org)

      assert Categories.list(org) == []
    end
  end
end
