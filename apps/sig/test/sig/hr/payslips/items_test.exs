defmodule Sig.HR.Payslips.ItemsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item

  describe "list_by_payslip/1" do
    test "lists payslip items by payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        outside_item_description: "Complemento Salário",
        outside_item_entry_type: :credit
      )

      insert(:payslip_item, org: org, payslip: payslip, category: health_insurance_category)
      insert(:payslip_item, org: org, payslip: payslip, category: salary_category)

      assert [
               %Item{code: "1", description: "SALÁRIO", entry_type: :credit},
               %Item{code: "115", description: "ASSISTÊNCIA MÉDICA", entry_type: :debit},
               %Item{code: nil, description: "Complemento Salário", entry_type: :credit}
             ] = Items.list_by_payslip(payslip)
    end

    test "payslip has no items" do
      payslip = insert(:payslip)

      assert Items.list_by_payslip(payslip) == []
    end
  end

  describe "get/2" do
    test "gets a payslip_item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      %{id: id} = insert(:payslip_item, org: org, payslip: payslip, category: category)

      assert %Item{id: ^id, code: "1", description: "SALÁRIO", entry_type: :credit} =
               Items.get(payslip, id)
    end

    test "gets a payslip_outside_item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      %{id: id} =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          outside_item_description: "Complemento Salário",
          outside_item_entry_type: :credit
        )

      assert %Item{id: ^id, code: nil, description: "Complemento Salário", entry_type: :credit} =
               Items.get(payslip, id)
    end

    test "item belongs to other payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      other_payslip = insert(:payslip, org: org)

      %{id: id} =
        insert(:payslip_outside_item,
          org: org,
          payslip: other_payslip,
          outside_item_description: "Complemento Salário",
          outside_item_entry_type: :credit
        )

      assert Items.get(payslip, id) == nil
    end

    test "item doesn't exist" do
      payslip = insert(:payslip)

      assert Items.get(payslip, UUID.generate()) == nil
    end
  end
end
