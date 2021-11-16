defmodule Sig.HR.Payslips.DeleteTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Delete
  alias Sig.HR.Payslips.Payslip

  describe "call/1" do
    test "deletes a payslip" do
      %{id: id} = payslip = insert(:payslip)

      assert {:ok, %Payslip{id: ^id}} = Delete.call(payslip)

      refute Repo.get_by(Payslip, id: id, org_id: payslip.org_id)
    end

    test "when payslip is initially closed" do
      payslip = insert(:payslip, is_closed: true)

      assert Delete.call(payslip) == {:error, "can't delete a closed payslip"}

      assert Repo.get_by(Payslip, id: payslip.id, org_id: payslip.org_id)
    end

    test "when payslip is closed after is loaded" do
      payslip = insert(:payslip)

      # Close payslip
      Repo.update!(change(payslip, is_closed: true))

      assert Delete.call(payslip) == {:error, "can't delete a closed payslip"}

      assert Repo.get_by(Payslip, id: payslip.id, org_id: payslip.org_id)
    end

    test "when payslip has payslip items" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      insert(:payslip_outside_item, org: org, payslip: payslip, amount: 100_00)

      # Update payslip amount
      Repo.update!(change(payslip, amount: 100_00))

      assert Delete.call(payslip) == {:error, "can't delete a payslip with items"}

      assert Repo.get_by(Payslip, id: payslip.id, org_id: payslip.org_id)
    end

    test "when payslip has payslip payables" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      item =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          entry_type: :credit,
          amount: 100_00
        )

      # Update payslip amount
      updated_payslip = Repo.update!(change(payslip, amount: 100_00))

      payable = insert(:payable_cash, org: org, amount: 100_00, target: :payslip)
      insert(:payslip_payable, org: org, payslip: payslip, payable: payable)

      # Delete item
      Repo.delete!(item)

      # Update payslip amount
      Repo.update!(change(updated_payslip, amount: 0))

      assert Delete.call(payslip) == {:error, "can't delete a payslip with payables"}

      assert Repo.get_by(Payslip, id: payslip.id, org_id: payslip.org_id)
    end
  end
end
