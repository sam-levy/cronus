defmodule Sig.Finance.Payables.PayablesForPayslip.Create do
  import Ecto.Changeset, only: [add_error: 3, put_change: 3]
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Payslip{} = payslip, %{} = attrs, opts \\ []) do
    changeset = build_changeset(payslip, attrs, opts)

    with %{valid?: true} <- changeset,
         true <- valid_amount?(payslip, changeset, opts) do
      Multi.new()
      |> Multi.insert(:payable, changeset)
      |> Multi.run(:payslip_payable, fn _, %{payable: payable} ->
        PayslipPayables.create(payslip, payable, opts)
      end)
      |> Multi.run(:update_auto_adjustable_amount_payable, fn _, _ ->
        PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
      end)
      |> Repo.transaction()
      |> handle_return()
    else
      %{valid?: false} -> {:error, changeset}
      false -> {:error, add_error(changeset, :amount, "can't exceed payslip amount")}
    end
  end

  defp build_changeset(payslip, attrs, opts) do
    changeset =
    attrs
    |> Map.put(:org_id, payslip.org_id)
    |> Map.put(:target, :payslip)
    |> Payable.create_changeset()

    if Keyword.get(opts, :is_auto_adjustable_amount, false) do
      put_change(changeset, :amount, nil)
    else
      changeset
    end
  end

  defp valid_amount?(payslip, changeset, opts) do
    if Keyword.get(opts, :is_auto_adjustable_amount, false) do
      true
    else
      amount_sum = sum_non_adjustable_payables_amounts(payslip)
      payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

      new_amount =
        changeset.changes
        |> Map.get(:amount, Money.new(0))
        |> Money.add(amount_sum)

      payslip.amount >= new_amount
    end
  end

  def sum_non_adjustable_payables_amounts(payslip) do
    payslip
    |> PayablesForPayslip.query_by_payslip()
    |> where(
      [_payslip, payslip_payable: payslip_payable],
      not payslip_payable.is_auto_adjustable_amount
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
