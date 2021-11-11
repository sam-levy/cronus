defmodule Sig.Finance.Payables.PayablesForPayslip.Create do
  import Ecto.Changeset, only: [add_error: 3, apply_action: 2]
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Changeset
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              opts: nil,
              attrs: nil,
              return: nil,
              payslip: nil,
              changeset: nil,
              is_auto_adjustable_amount: nil
  end

  def call(%Payslip{} = payslip, %{} = attrs, opts \\ []) do
    %Context{
      opts: opts,
      attrs: attrs,
      payslip: payslip,
      is_auto_adjustable_amount: Keyword.get(opts, :is_auto_adjustable_amount, false)
    }
    |> build_changeset()
    |> validate_amount()
    |> validate_credit_bank_account()
    |> validate_check_bank_account()
    |> create_multi()
    |> handle_return()
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
      %{valid?: true} = changeset -> %{context | changeset: changeset}
      changeset -> put_error(context, changeset)
    end
  end

  defp handle_changeset_amount(changeset, true), do: Changeset.drop_changes(changeset, :amount)
  defp handle_changeset_amount(changeset, false), do: changeset

  defp validate_amount(%{status: :halt} = context), do: context

  defp validate_amount(%{is_auto_adjustable_amount: true} = context), do: context

  defp validate_amount(context) do
    %{payslip: payslip, changeset: changeset} = context

    existing_non_adjustable_amount_sum = sum_non_adjustable_payables_amounts(payslip)
    payslip = Payslips.get_by(org_id: payslip.org_id, id: payslip.id)

    new_non_adjustable_amount_sum =
      changeset.changes
      |> Map.get(:amount, Money.new(0))
      |> Money.add(existing_non_adjustable_amount_sum)

    if payslip.amount >= new_non_adjustable_amount_sum do
      context
    else
      {:error, changeset} =
        changeset
        |> add_error(:amount, "can't exceed payslip amount")
        |> apply_action(:insert)

      put_error(context, changeset)
    end
  end

  def sum_non_adjustable_payables_amounts(payslip) do
    payslip
    |> PayablesForPayslip.query_by_payslip()
    |> where([payslip_payable: payslip_payable], not payslip_payable.is_auto_adjustable_amount)
    |> Repo.aggregate(:sum, :amount)
    |> case do
      %Money{} = sum -> sum
      nil -> Money.new(0)
    end
  end

  defp validate_credit_bank_account(%{status: :halt} = context), do: context

  defp validate_credit_bank_account(context) do
    %{payslip: payslip, changeset: changeset} = context

    case PayablesForPayslip.validate_credit_bank_account(changeset, payslip) do
      {:ok, _} -> context
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp validate_check_bank_account(%{status: :halt} = context), do: context

  defp validate_check_bank_account(context) do
    %{payslip: payslip, changeset: changeset} = context

    case PayablesForPayslip.validate_check_bank_account(changeset, payslip) do
      {:ok, _} -> context
      {:error, changeset} -> put_error(context, changeset)
    end
  end

  defp create_multi(%{status: :halt} = context), do: context

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
      {:ok, %{payable: payable}} -> %{context | return: payable}
      {:error, _operation, reason, _changes} -> put_error(context, reason)
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

  defp put_error(context, error), do: %{context | status: :halt, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halt, return: {:error, error}}), do: {:error, error}
end
