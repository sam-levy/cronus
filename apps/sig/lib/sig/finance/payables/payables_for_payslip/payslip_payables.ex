defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayables do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  # TODO: Add test
  def create(%Payslip{} = payslip, %Payable{} = payable, opts \\ []) do
    Multi.new()
    |> Multi.insert(:payslip_payable, %PayslipPayable{
      org_id: payslip.org_id,
      payslip_id: payslip.id,
      payable_id: payable.id
    })
    |> Multi.run(
      :set_is_auto_adjustable_amount,
      fn _, %{payslip_payable: payslip_payable} ->
        if Keyword.get(opts, :is_auto_adjustable_amount, false) do
          set_is_auto_adjustable_amount(payslip, payable.id)
        else
          {:ok, payslip_payable}
        end
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{payslip_payable: payslip_payable}} -> {:ok, payslip_payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  # TODO: Add test
  def set_is_auto_adjustable_amount(%Payslip{org_id: org_id, id: payslip_id}, payable_id)
      when is_binary(payable_id) do
    Multi.new()
    |> Multi.update_all(
      :unset_existing,
      where(PayslipPayable,
        org_id: ^org_id,
        payslip_id: ^payslip_id,
        is_auto_adjustable_amount: true
      ),
      set: [is_auto_adjustable_amount: false]
    )
    |> Multi.update_all(
      :set_is_auto_adjustable_amount,
      PayslipPayable
      |> where(
        org_id: ^org_id,
        payslip_id: ^payslip_id,
        payable_id: ^payable_id
      )
      |> select([payslip_payable], payslip_payable),
      set: [is_auto_adjustable_amount: true]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{set_is_auto_adjustable_amount: {1, [payslip_payable]}}} -> {:ok, payslip_payable}
      {:ok, %{set_is_auto_adjustable_amount: {0, []}}} -> {:error, :not_found}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end
end
