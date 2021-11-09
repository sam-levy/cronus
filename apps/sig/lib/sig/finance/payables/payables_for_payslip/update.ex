defmodule Sig.Finance.Payables.PayablesForPayslip.Update do
  import Ecto.Changeset, only: [add_error: 3, apply_action: 2]
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Changeset
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              attrs: nil,
              return: nil,
              payslip: nil,
              payable: nil,
              changeset: nil,
              is_auto_adjustable_amount: nil
  end

  def call(%Payslip{} = payslip, %Payable{} = payable, %{} = attrs) do
    %Context{
      attrs: attrs,
      payslip: payslip,
      payable: payable
    }
    |> set_is_auto_adjustable_amount()
    |> build_changeset()
    |> validate_amount()
    |> validate_credit_bank_account()
    |> validate_check_bank_account()
    |> update_multi()
    |> handle_return()
  end

  defp set_is_auto_adjustable_amount(context) do
    %{payslip: payslip, payable: payable} = context

    PayslipPayable
    |> Repo.get_by(
      org_id: payslip.org_id,
      payslip_id: payslip.id,
      payable_id: payable.id
    )
    |> case do
      %PayslipPayable{} = payslip_payable ->
        %{context | is_auto_adjustable_amount: payslip_payable.is_auto_adjustable_amount}

      nil ->
        put_error(context, "payable doesn't belong to payslip")
    end
  end

  defp build_changeset(%{status: :halt} = context), do: context

  defp build_changeset(context) do
    context.payable
    |> Payable.update_changeset(context.attrs)
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
    %{payslip: payslip, payable: payable, changeset: changeset} = context

    existing_non_adjustable_amount_sum = sum_non_adjustable_payables_amounts(payslip, payable.id)
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
        |> apply_action(:update)

      put_error(context, changeset)
    end
  end

  def sum_non_adjustable_payables_amounts(payslip, payable_id) do
    payslip
    |> PayablesForPayslip.query_by_payslip()
    |> where(
      [payslip_payable: payslip_payable],
      not payslip_payable.is_auto_adjustable_amount and
        payslip_payable.payable_id != ^payable_id
    )
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

  defp update_multi(%{status: :halt} = context), do: context

  defp update_multi(context) do
    Multi.new()
    |> Multi.run(:handle_non_auto_adjustable_amount_subtract, fn _, _ ->
      handle_non_auto_adjustable_amount_subtract(context)
    end)
    |> Multi.update(:payable, context.changeset)
    |> Multi.run(:handle_non_auto_adjustable_amount, fn _, _ ->
      handle_non_auto_adjustable_amount(context)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{payable: payable}} -> %{context | return: payable}
      {:error, _operation, reason, _changes} -> put_error(context, reason)
    end
  end

  defp handle_non_auto_adjustable_amount_subtract(
         %{is_auto_adjustable_amount: false, changeset: %{changes: %{amount: changeset_amount}}} =
           context
       )
       when not is_nil(changeset_amount) do
    %{payslip: payslip, payable: payable} = context

    case Money.compare(changeset_amount, payable.amount) do
      -1 ->
        {:ok, nil}

      0 ->
        {:ok, nil}

      1 ->
        amount_diff = Money.subtract(changeset_amount, payable.amount)

        PayablesForPayslip.update_auto_adjustable_amount_payable(payslip, subtract: amount_diff)
    end
  end

  defp handle_non_auto_adjustable_amount_subtract(_context), do: {:ok, nil}

  defp handle_non_auto_adjustable_amount(
         %{is_auto_adjustable_amount: false, changeset: %{changes: %{amount: changeset_amount}}} =
           context
       )
       when not is_nil(changeset_amount) do
    %{payslip: payslip, payable: payable} = context

    case Money.compare(changeset_amount, payable.amount) do
      -1 ->
        PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)

      0 ->
        {:ok, nil}

      1 ->
        {:ok, nil}
    end
  end

  defp handle_non_auto_adjustable_amount(_context), do: {:ok, nil}

  # defp handle_auto_adjustable_amount(%{is_auto_adjustable_amount: true} = context) do
  #   PayablesForPayslip.update_auto_adjustable_amount_payable(context.payslip)
  # end

  # defp handle_auto_adjustable_amount(_context), do: {:ok, nil}

  defp put_error(context, error), do: %{context | status: :halt, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halt, return: {:error, error}}), do: {:error, error}
end
