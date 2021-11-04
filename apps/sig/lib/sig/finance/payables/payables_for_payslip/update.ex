defmodule Sig.Finance.Payables.PayablesForPayslip.Update do
  import Ecto.Changeset, only: [add_error: 3, put_change: 3]
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Payslip{} = payslip, %Payable{} = payable, %{} = attrs) do
    payslip_payable =
      Repo.get_by(PayslipPayable,
        org_id: payslip.org_id,
        payslip_id: payslip.id,
        payable_id: payable.id
      )

    changeset = build_changeset(payable, attrs, payslip_payable)

    with %{valid?: true} <- changeset,
         true <- valid_amount?(payslip, changeset, payslip_payable) do
      Multi.new()
      |> Multi.update(:payable, changeset)
      |> Multi.run(:update_auto_adjustable_amount_payable, fn _, _ ->
        if payslip_payable.is_auto_adjustable_amount do
          {:ok, nil}
        else
          PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
        end
      end)
      |> Repo.transaction()
      |> handle_return()
    else
      %{valid?: false} -> {:error, changeset}
      false -> {:error, add_error(changeset, :amount, "can't exceed payslip amount")}
    end
  end

  defp build_changeset(payable, attrs, %{is_auto_adjustable_amount: true}) do
    payable
    |> Payable.update_changeset(attrs)
    |> put_change(:amount, nil)
  end

  defp build_changeset(payable, attrs, _payslip_payable) do
    Payable.update_changeset(payable, attrs)
  end

  defp valid_amount?(_payslip, _changeset, %{is_auto_adjustable_amount: true}), do: true

  defp valid_amount?(payslip, changeset, payslip_payable) do
    amount_sum = sum_non_adjustable_payables_amounts(payslip, payslip_payable.payable_id)
    payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

    new_amount =
      changeset.changes
      |> Map.get(:amount, Money.new(0))
      |> Money.add(amount_sum)

    payslip.amount >= new_amount
  end

  def sum_non_adjustable_payables_amounts(payslip, payable_id) do
    payslip
    |> PayablesForPayslip.query_by_payslip()
    |> where(
      [_payslip, payslip_payable: payslip_payable],
      not payslip_payable.is_auto_adjustable_amount and
        payslip_payable.payable_id != ^payable_id
    )
    |> Repo.aggregate(:sum, :amount)
    |> case do
      %Money{} = sum -> sum
      nil -> Money.new(0)
    end
  end

  defp handle_return({:ok, %{payable: payable}}), do: {:ok, payable}
  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}
end
