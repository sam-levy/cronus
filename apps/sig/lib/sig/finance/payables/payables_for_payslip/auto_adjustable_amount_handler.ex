defmodule Sig.Finance.Payables.PayablesForPayslip.AutoAdjustableAmountHandler do
  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def set_as_auto_adjustable_amount(_payslip, %Payable{is_fulfilled: true}) do
    {:error, "can't modify a fulfilled payable"}
  end

  def set_as_auto_adjustable_amount(_payslip, %Payable{authorized_by_id: id})
      when is_binary(id) do
    {:error, "can't modify an authorized payable"}
  end

  def set_as_auto_adjustable_amount(%Payslip{} = payslip, %Payable{} = payable) do
    Multi.new()
    |> Multi.run(:set_payslip_payable_as_auto_adjustable_amount, fn _, _ ->
      PayslipPayables.set_as_auto_adjustable_amount(payslip, payable)
    end)
    |> Multi.run(:update_auto_adjustable_amount_payable, fn _, _ ->
      PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_auto_adjustable_amount_payable: payable}} -> {:ok, payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end
end
