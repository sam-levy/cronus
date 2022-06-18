defmodule Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayable do
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Payslip{} = payslip, opts \\ []) do
    %{payslip: payslip, opts: opts}
    |> Extep.new()
    |> Extep.run(&list_payables/1, :payables)
    |> Extep.run(&fetch_auto_adjustable_amount_payable/1, :auto_adjustable_amount_payable)
    |> Extep.run(&sum_non_adjustable_payables_amounts/1, :non_adjustable_payables_amount_sum)
    |> Extep.run(
      &update_auto_adjustable_amount_payable/1,
      :updated_auto_adjustable_amount_payable
    )
    |> Extep.return(:updated_auto_adjustable_amount_payable)
  end

  defp list_payables(context) do
    case Payables.list_by(context.payslip) do
      [] -> :halt
      payables -> {:ok, payables}
    end
  end

  defp fetch_auto_adjustable_amount_payable(context) do
    case Enum.find(context.payables, & &1.payslip_payable.is_auto_adjustable_amount) do
      %Payable{financial_transaction_id: nil} = payable -> {:ok, payable}
      %Payable{} -> :halt
      nil -> :halt
    end
  end

  defp sum_non_adjustable_payables_amounts(context) do
    sum =
      Enum.reduce(context.payables, Money.new(0), fn
        %Payable{
          payslip_payable: %PayslipPayable{is_auto_adjustable_amount: false},
          amount: amount
        },
        acc ->
          Money.add(acc, amount)

        _payable, acc ->
          acc
      end)

    {:ok, sum}
  end

  defp update_auto_adjustable_amount_payable(context) do
    %{
      opts: opts,
      payslip: payslip,
      auto_adjustable_amount_payable: payable,
      non_adjustable_payables_amount_sum: non_adjustable_payables_amount_sum
    } = context

    payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

    payments_in_advance_items_amount_sum = Items.sum_payments_in_advance_items_by_payslip(payslip)

    adjusted_amount =
      payslip.amount
      |> Money.subtract(non_adjustable_payables_amount_sum)
      |> Money.add(payments_in_advance_items_amount_sum)
      |> handle_adjustment(opts)

    payable
    |> Payable.update_changeset(%{amount: adjusted_amount})
    |> Repo.update()
    |> case do
      {:ok, payable} -> {:ok, payable}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp handle_adjustment(amount, opts) do
    case Keyword.get(opts, :subtract) do
      nil -> amount
      amount_to_subtract -> Money.subtract(amount, amount_to_subtract)
    end
  end
end
