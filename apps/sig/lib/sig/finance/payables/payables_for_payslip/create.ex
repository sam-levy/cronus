defmodule Sig.Finance.Payables.PayablesForPayslip.Create do
  import Ecto.Changeset, only: [add_error: 3, apply_action: 2]

  alias Ecto.Multi

  alias Sig.Changeset
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.HR
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Payslip{} = payslip, %{} = attrs, opts \\ []) do
    %{
      opts: opts,
      attrs: attrs,
      payslip: payslip,
      is_auto_adjustable_amount: Keyword.get(opts, :is_auto_adjustable_amount, false)
    }
    |> Extep.new()
    |> Extep.run(&build_changeset/1, :changeset)
    |> Extep.run(&validate_amount/1)
    |> Extep.run(&validate_credit_bank_account/1)
    |> Extep.run(&validate_check_debit_bank_account/1)
    |> Extep.run(&create_multi/1, :payable)
    |> Extep.return(:payable)
  end

  defp build_changeset(context) do
    %{payslip: payslip, attrs: attrs} = context

    attrs
    |> Map.put(:org_id, payslip.org_id)
    |> Map.put(:target, :payslip)
    |> Map.put_new(:reference_date, Date.beginning_of_month(payslip.start_date))
    |> Payable.create_changeset()
    |> handle_changeset_amount(context.is_auto_adjustable_amount)
    |> case do
      %{valid?: true} = changeset -> {:ok, changeset}
      changeset -> {:error, changeset}
    end
  end

  defp handle_changeset_amount(changeset, true), do: Changeset.drop_changes(changeset, :amount)
  defp handle_changeset_amount(changeset, false), do: changeset

  defp validate_amount(%{is_auto_adjustable_amount: true}), do: :ok

  defp validate_amount(context) do
    %{payslip: payslip, changeset: changeset} = context

    existing_non_adjustable_amount_sum =
      PayablesForPayslip.sum_non_adjustable_payables_amounts(payslip)

    payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

    new_non_adjustable_amount_sum =
      changeset.changes
      |> Map.get(:amount, Money.new(0))
      |> Money.add(existing_non_adjustable_amount_sum)

    payments_in_advance_sum = HR.sum_payments_in_advance_items_by_payslip(payslip)

    if Money.add(payslip.amount, payments_in_advance_sum) >= new_non_adjustable_amount_sum do
      :ok
    else
      {:error, changeset} =
        changeset
        |> add_error(
          :amount,
          "o valor total dos pagáveis não pode exceder o valor do holerite mais os adiantamentos"
        )
        |> apply_action(:insert)

      {:error, changeset}
    end
  end

  defp validate_credit_bank_account(context) do
    %{payslip: payslip, changeset: changeset} = context

    case PayablesForPayslip.validate_credit_bank_account(changeset, payslip) do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp validate_check_debit_bank_account(context) do
    %{payslip: payslip, changeset: changeset} = context

    case PayablesForPayslip.validate_check_debit_bank_account(changeset, payslip) do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp create_multi(context) do
    %{payslip: payslip, changeset: changeset, opts: opts} = context

    Multi.new()
    |> Multi.run(:handle_non_auto_adjustable_amount, fn _, _ ->
      handle_non_auto_adjustable_amount(context)
    end)
    |> Multi.insert(:payable, changeset)
    |> Multi.run(:payslip_payable, fn _, %{payable: payable} ->
      PayslipPayables.create(payslip, payable, opts)
    end)
    |> Multi.run(:handle_auto_adjustable_amount, fn _, _ ->
      handle_auto_adjustable_amount(context)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{payable: payable}} -> {:ok, payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp handle_non_auto_adjustable_amount(
         %{is_auto_adjustable_amount: false, changeset: %{changes: %{amount: amount}}} = context
       )
       when not is_nil(amount) do
    %{payslip: payslip} = context

    PayablesForPayslip.update_auto_adjustable_amount_payable(payslip, subtract: amount)
  end

  defp handle_non_auto_adjustable_amount(_context), do: {:ok, nil}

  defp handle_auto_adjustable_amount(%{is_auto_adjustable_amount: true} = context) do
    PayablesForPayslip.update_auto_adjustable_amount_payable(context.payslip)
  end

  defp handle_auto_adjustable_amount(_context), do: {:ok, nil}
end
