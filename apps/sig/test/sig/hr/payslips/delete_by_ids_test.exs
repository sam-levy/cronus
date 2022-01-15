defmodule Sig.HR.Payslips.DeleteByIdsTest do
  use Sig.DataCase, async: true

  alias Sig.HR.Payslips.DeleteByIds
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

  describe "call/1" do
    test "deletes payslips by ids" do
      org = insert(:org)
      payslips = insert_list(2, :payslip, org: org, is_closed: false)

      Enum.each(payslips, fn payslip ->
        insert_list(2, :payslip_outside_item,
          org: org,
          payslip: payslip,
          amount: 100_00,
          entry_type: :credit
        )

        Repo.update!(change(payslip, amount: 200_00))

        payables = insert_list(2, :payable_cash, org: org, amount: 100_00)

        Enum.each(payables, fn payable ->
          insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
        end)
      end)

      payslip_ids = Enum.map(payslips, & &1.id)

      assert {:ok,
              %{
                payslips: [%Payslip{}, %Payslip{}],
                payables: [%Payable{}, %Payable{}, %Payable{}, %Payable{}]
              }} = DeleteByIds.call(org, payslip_ids)

      Enum.each(payslips, fn payslip ->
        refute Repo.get_by(Item, org_id: org.id, payslip_id: payslip.id)
        refute Repo.get_by(Payslip, org_id: org.id, id: payslip.id)
        refute Repo.get_by(PayslipPayable, org_id: org.id, payslip_id: payslip.id)
      end)

      assert Payable |> where(org_id: ^org.id) |> Repo.all() == []
    end

    test "when payslips has no items nor payables" do
      org = insert(:org)
      payslips = insert_list(2, :payslip, org: org, is_closed: false)

      payslip_ids = Enum.map(payslips, & &1.id)

      assert {:ok, %{payslips: [%Payslip{}, %Payslip{}], payables: nil}} =
               DeleteByIds.call(org, payslip_ids)

      Enum.each(payslips, fn payslip ->
        refute Repo.get_by(Payslip, org_id: org.id, id: payslip.id)
      end)
    end

    test "when payslip is closed" do
      org = insert(:org)
      closed_payslip = insert(:payslip, org: org, is_closed: false)
      open_payslip = insert(:payslip, org: org, is_closed: false)

      Enum.each([closed_payslip, open_payslip], fn payslip ->
        insert_list(2, :payslip_outside_item,
          org: org,
          payslip: payslip,
          amount: 100_00,
          entry_type: :credit
        )

        Repo.update!(change(payslip, amount: 200_00))

        payables = insert_list(2, :payable_cash, org: org, amount: 100_00)

        Enum.each(payables, fn payable ->
          insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
        end)
      end)

      Repo.update!(change(closed_payslip, is_closed: true))

      payslip_ids = [closed_payslip.id, open_payslip.id]

      assert DeleteByIds.call(org, payslip_ids) == {:error, "Existem holerites fechados"}
    end

    test "when payslip has associated overtimes" do
      org = insert(:org)
      payslip_with_overtimes = insert(:payslip, org: org, is_closed: false)
      open_payslip = insert(:payslip, org: org, is_closed: false)

      Enum.each([payslip_with_overtimes, open_payslip], fn payslip ->
        insert_list(2, :payslip_outside_item,
          org: org,
          payslip: payslip,
          amount: 100_00,
          entry_type: :credit
        )

        Repo.update!(change(payslip, amount: 200_00))

        payables = insert_list(2, :payable_cash, org: org, amount: 100_00)

        Enum.each(payables, fn payable ->
          insert(:payslip_payable, org: org, payslip: payslip, payable: payable)
        end)
      end)

      insert(:employee_overtime,
        org: org,
        payslip: payslip_with_overtimes,
        registration: payslip_with_overtimes.registration
      )

      payslip_ids = [payslip_with_overtimes.id, open_payslip.id]

      assert DeleteByIds.call(org, payslip_ids) ==
               {:error, "Existem horas extras associadas a holerites"}
    end

    test "when id list is empty" do
      org = insert(:org)

      assert DeleteByIds.call(org, []) == {:ok, nil}
    end
  end
end
