defmodule Sig.Finance.Payables.PayablesForPayslip.Delete do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Payslip{}, %Payable{is_fulfilled: true}) do
    {:error, "cannot delete a fulfilled payable"}
  end

  def call(%Payslip{} = payslip, %Payable{target: :payslip} = payable) do
    Multi.new()
    |> Multi.delete_all(
      :payslip_payable,
      PayslipPayable
      |> where(org_id: ^payslip.org_id, payslip_id: ^payslip.id, payable_id: ^payable.id)
      |> select([payslip_payable], payslip_payable)
    )
    |> Multi.delete(:payable, payable)
    |> Multi.run(
      :update_auto_adjustable_amount_payable,
      fn _, %{payslip_payable: {1, [payslip_payable]}} ->
        if payslip_payable.is_auto_adjustable_amount do
          {:ok, nil}
        else
          PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
        end
      end
    )
    |> Repo.transaction()
    |> handle_return()
  end

  defp handle_return({:ok, %{payable: payable}}), do: {:ok, payable}
  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}
end
