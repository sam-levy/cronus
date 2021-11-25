defmodule Sig.HR.Payslips.DeleteTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Delete
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.Groups.Group

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

    test "when payslip has overtimes" do
      org = insert(:org)
      date = ~D[2021-01-01]
      registration = insert(:employee_registration, org: org, admission_date: date)
      payslip = insert(:payslip, org: org, registration: registration, start_date: date)

      insert(:employee_overtime,
        org: org,
        registration: registration,
        payslip: payslip,
        date: date
      )

      assert Delete.call(payslip) == {:error, "can't delete a payslip with overtimes"}

      assert Repo.get_by(Payslip, id: payslip.id, org_id: payslip.org_id)
    end

    test "deletes a payslip group when there are no other payslip" do
      date = ~D[2021-01-01]
      type = :regular

      org = insert(:org)
      group = insert(:payslip_group, org: org, date: date, type: type)

      %{id: id} = payslip = insert(:payslip, org: org, group: group, start_date: date, type: type)

      assert {:ok, %Payslip{id: ^id}} = Delete.call(payslip)

      refute Repo.get_by(Payslip, id: id, org_id: org.id)
      refute Repo.get_by(Group, id: group.id, org_id: org.id)
    end

    test "doesn't delete a payslip group when there are other payslips" do
      date = ~D[2021-01-01]
      type = :regular

      org = insert(:org)
      %{id: group_id} = group = insert(:payslip_group, org: org, date: date, type: type)
      insert(:payslip, org: org, group: group, start_date: date, type: type)

      %{id: payslip_id} =
        payslip = insert(:payslip, org: org, group: group, start_date: date, type: type)

      assert {:ok, %Payslip{id: ^payslip_id}} = Delete.call(payslip)

      refute Repo.get_by(Payslip, id: payslip_id, org_id: org.id)

      assert %Group{id: ^group_id} = Repo.get_by(Group, id: group_id, org_id: org.id)
    end
  end
end
