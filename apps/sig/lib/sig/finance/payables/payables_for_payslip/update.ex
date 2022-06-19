defmodule Sig.Finance.Payables.PayablesForPayslip.Update do
  import Ecto.Changeset, only: [add_error: 3, apply_action: 2]

  alias Ecto.Multi

  alias Sig.Changeset
  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.HR
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @fulfilled_payable_message "can't modify a fulfilled payable"
  @authorized_payable_message "can't modify an authorized payable"

  def call(%Payslip{}, %Payable{financial_transaction_id: ft_id}, %{}) when is_binary(ft_id) do
    {:error, @fulfilled_payable_message}
  end

  def call(%Payslip{}, %Payable{authorized_by_id: id}, %{}) when is_binary(id) do
    {:error, @authorized_payable_message}
  end

  def call(%Payslip{} = payslip, %Payable{} = payable, %{} = attrs) do
    %{
      attrs: attrs,
      payslip: payslip,
      payable: payable
    }
    |> Extep.new()
    |> Extep.run(&set_is_auto_adjustable_amount/1, :is_auto_adjustable_amount)
    |> Extep.run(&build_changeset/1, :changeset)
    |> Extep.run(&validate_amount/1)
    |> Extep.run(&validate_credit_bank_account/1)
    |> Extep.run(&validate_check_debit_bank_account/1)
    |> Extep.return(&update_multi/1)
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
        {:ok, payslip_payable.is_auto_adjustable_amount}

      nil ->
        {:error, "payable doesn't belong to payslip"}
    end
  end

  defp build_changeset(context) do
    context.payable
    |> Payable.update_changeset(context.attrs)
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
    %{payslip: payslip, payable: payable, changeset: changeset} = context

    existing_non_adjustable_amount_sum =
      PayablesForPayslip.sum_non_adjustable_payables_amounts(payslip, payable)

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
        |> apply_action(:update)

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

  defp update_multi(context) do
    Multi.new()
    |> Multi.run(:payable, fn _, _ -> ensure_valid_payable_to_update(context.payable) end)
    |> Multi.run(:handle_non_auto_adjustable_amount_subtract, fn _, %{payable: payable} ->
      handle_non_auto_adjustable_amount_subtract(context, payable)
    end)
    |> Multi.update(:update_payable, context.changeset)
    |> Multi.run(:handle_non_auto_adjustable_amount, fn _, %{payable: payable} ->
      handle_non_auto_adjustable_amount(context, payable)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_payable: payable}} -> {:ok, payable}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp ensure_valid_payable_to_update(%Payable{org_id: org_id, id: id}) do
    case Payables.get_by(id: id, org_id: org_id) do
      %Payable{financial_transaction_id: ft_id} when is_binary(ft_id) ->
        {:error, @fulfilled_payable_message}

      %Payable{authorized_by_id: ab_id} when is_binary(ab_id) ->
        {:error, @authorized_payable_message}

      %Payable{} = payable ->
        {:ok, payable}
    end
  end

  defp handle_non_auto_adjustable_amount_subtract(
         %{is_auto_adjustable_amount: false, changeset: %{changes: %{amount: changeset_amount}}} =
           context,
         payable
       )
       when not is_nil(changeset_amount) do
    %{payslip: payslip} = context

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

  defp handle_non_auto_adjustable_amount_subtract(_context, _payable), do: {:ok, nil}

  defp handle_non_auto_adjustable_amount(
         %{is_auto_adjustable_amount: false, changeset: %{changes: %{amount: changeset_amount}}} =
           context,
         payable
       )
       when not is_nil(changeset_amount) do
    %{payslip: payslip} = context

    case Money.compare(changeset_amount, payable.amount) do
      -1 ->
        PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)

      0 ->
        {:ok, nil}

      1 ->
        {:ok, nil}
    end
  end
end
