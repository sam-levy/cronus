defmodule Sig.HR.Payslips.RecurringItemModelsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.RecurringItemModels

  describe "list/1" do
    test "lists payslips recurring item models from an organization" do
      org = insert(:org)

      insert({:payslip_recurring_item_model, :fixed_amount}, org: org)
      insert({:payslip_recurring_item_model, :percentage}, org: org)
      _to_ignore = insert({:payslip_recurring_item_model, :fixed_amount})

      assert return = RecurringItemModels.list(org)

      assert Enum.count(return) == 2

      assert Enum.all?(return, & &1.org_id == org.id)
    end

    test "when org has no recurring item" do
      org = insert(:org)

      assert RecurringItemModels.list(org) == []
    end
  end
end
