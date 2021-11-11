defmodule Sig.Finance.Payables.PayablesForPayslip.Delete do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @fulfilled_payable_message "can't delete a fulfilled payable"

  def call(%Payslip{}, %Payable{is_fulfilled: true}) do
    {:error, @fulfilled_payable_message}
  end

  def call(%Payslip{} = payslip, %Payable{target: :payslip} = payable) do
    Multi.new()
    |> Multi.run(:payable, fn _, _ -> ensure_payable_is_not_fulfilled(payable) end)
    |> Multi.delete_all(
      :payslip_payable,
      PayslipPayable
      |> where(org_id: ^payslip.org_id, payslip_id: ^payslip.id, payable_id: ^payable.id)
      |> select([payslip_payable], payslip_payable)
    )
    |> Multi.delete(:delete_payable, payable)
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

  defp ensure_payable_is_not_fulfilled(%Payable{org_id: org_id, id: id}) do
    case Payables.get_by(id: id, org_id: org_id) do
      %{is_fulfilled: false} = payable -> {:ok, payable}
      _payable -> {:error, @fulfilled_payable_message}
    end
  end

  defp handle_return({:ok, %{delete_payable: payable}}), do: {:ok, payable}
  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}
end
