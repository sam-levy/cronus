defmodule Sig.Finance.Payables.PayablesForPayslip.CreateStandardPayables do
  alias Ecto.Multi

  alias Sig.HR.Registrations.Registration
  alias Sig.Finance.Banks
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Registration{} = registration, %Payslip{} = payslip, payslip_items, %{} = due_dates)
      when is_list(payslip_items) do
    %{
      registration: registration,
      payslip: payslip,
      payslip_items: payslip_items,
      due_dates: due_dates
    }
    |> Extep.new()
    |> Extep.run(&validate_payslip_items/1)
    |> Extep.run(&validate_due_dates/1)
    |> Extep.run(&fetch_bank_account/1, :bank_account)
    |> Extep.run(&set_financial_transaction_type/1, :financial_transaction_type)
    |> Extep.return(&create_multi/1)
  end

  defp validate_payslip_items(%{payslip_items: []}), do: :ok

  defp validate_payslip_items(%{payslip_items: payslip_items, payslip: payslip}) do
    if Enum.all?(payslip_items, &valid_item?(&1, payslip.id)),
      do: :ok,
      else: {:error, "payslip items doesn't belong to payslip"}
  end

  defp valid_item?(%Item{payslip_id: payslip_id}, payslip_id), do: true
  defp valid_item?(_item, _payslip_id), do: false

  defp validate_due_dates(context) do
    case context.due_dates do
      %{payment_advance_date: %Date{}, salary_date: %Date{}} -> :ok
      _ -> {:error, "invalid payments due dates"}
    end
  end

  defp fetch_bank_account(context) do
    %{registration: registration, payslip: payslip} = context

    case Banks.fetch_entity_active_primary_bank_account(
           payslip.org_id,
           registration.individual_id
         ) do
      {:ok, account} -> {:ok, account}
      {:error, :not_found} -> {:ok, :not_found}
    end
  end

  defp set_financial_transaction_type(%{bank_account: :not_found}), do: {:ok, :cash}
  defp set_financial_transaction_type(_context), do: {:ok, :bank_transfer}

  defp create_multi(context) do
    Multi.new()
    |> Multi.run(:payment_advance, fn _, _ -> create_payment_advance(context) end)
    |> Multi.run(:salary, fn _, _ -> create_salary(context) end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> {:ok, changes}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp create_payment_advance(context) do
    case sum_payment_advance_amounts(context.payslip_items) do
      %Money{amount: 0} ->
        {:ok, nil}

      %Money{amount: amount} ->
        attrs =
          %{
            amount: amount,
            due_date: context.due_dates.payment_advance_date,
            financial_transaction_type: context.financial_transaction_type,
            description: "Adiantamento de Salário"
          }
          |> handle_bank_account(context.bank_account)

        PayablesForPayslip.create(context.payslip, attrs)
    end
  end

  defp sum_payment_advance_amounts(payslip_items) do
    Enum.reduce(payslip_items, Money.new(0), fn
      %{is_payment_advance: true, amount: amount}, acc -> Money.add(amount, acc)
      _item, acc -> acc
    end)
  end

  defp create_salary(context) do
    attrs =
      %{
        due_date: context.due_dates.salary_date,
        financial_transaction_type: context.financial_transaction_type,
        description: "Salário"
      }
      |> handle_bank_account(context.bank_account)

    PayablesForPayslip.create(context.payslip, attrs, is_auto_adjustable_amount: true)
  end

  defp handle_bank_account(%{financial_transaction_type: :cash} = attrs, _account), do: attrs

  defp handle_bank_account(%{financial_transaction_type: :bank_transfer} = attrs, account) do
    Map.put(attrs, :credit_bank_account_id, account.id)
  end
end
