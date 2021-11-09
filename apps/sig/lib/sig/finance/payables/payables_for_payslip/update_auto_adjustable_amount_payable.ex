defmodule Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayable do
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              opts: nil,
              return: nil,
              payslip: nil,
              payables: nil,
              non_adjustable_amount_sum: nil,
              auto_adjustable_amount_payable: nil
  end

  def call(%Payslip{} = payslip, opts \\ []) do
    %Context{payslip: payslip, opts: opts}
    |> list_payables()
    |> get_auto_adjustable_amount_payable()
    |> sum_non_adjustable_payables_amounts()
    |> do_update_auto_adjustable_amount_payable()
    |> handle_return()
  end

  defp list_payables(context) do
    case PayablesForPayslip.list_by_payslip(context.payslip) do
      [] -> %{context | status: :halt}
      payables -> %{context | payables: payables}
    end
  end

  defp get_auto_adjustable_amount_payable(%{status: :halt} = context), do: context

  defp get_auto_adjustable_amount_payable(context) do
    case Enum.find(context.payables, & &1.payslip_payable.is_auto_adjustable_amount) do
      %Payable{} = payable -> %{context | auto_adjustable_amount_payable: payable}
      nil -> %{context | status: :halt}
    end
  end

  defp sum_non_adjustable_payables_amounts(%{status: :halt} = context), do: context

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

    %{context | non_adjustable_amount_sum: sum}
  end

  defp do_update_auto_adjustable_amount_payable(%{status: :halt} = context), do: context

  defp do_update_auto_adjustable_amount_payable(context) do
    %{
      opts: opts,
      payslip: payslip,
      non_adjustable_amount_sum: sum,
      auto_adjustable_amount_payable: payable
    } = context

    payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

    adjusted_amount =
      payslip.amount
      |> Money.subtract(sum)
      |> handle_adjustment(opts)

    payable
    |> Payable.update_changeset(%{amount: adjusted_amount})
    |> Repo.update()
    |> case do
      {:ok, payable} -> %{context | return: payable}
      {:error, changeset} -> %{context | status: :halt, return: {:error, changeset}}
    end
  end

  defp handle_adjustment(amount, opts) do
    case Keyword.get(opts, :subtract) do
      nil -> amount
      amount_to_subtract -> Money.subtract(amount, amount_to_subtract)
    end
  end

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halt, return: nil}), do: {:ok, nil}
  defp handle_return(%{status: :halt, return: {:error, error}}), do: {:error, error}
end
