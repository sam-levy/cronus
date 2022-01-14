defmodule Sig.Finance.Payables.PayablesForPayslip.CreateStandardPayables do
  alias Ecto.Multi

  alias Sig.HR.Registrations.Registration
  alias Sig.Finance.Banks
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              return: nil,
              payslip: nil,
              due_dates: nil,
              registration: nil,
              bank_account: nil,
              payslip_items: nil,
              financial_transaction_type: nil
  end

  def call(%Registration{} = registration, %Payslip{} = payslip, payslip_items, %{} = due_dates)
      when is_list(payslip_items) do
    %Context{
      registration: registration,
      payslip: payslip,
      payslip_items: payslip_items,
      due_dates: due_dates
    }
    |> validate_payslip_items()
    |> validate_due_dates()
    |> get_bank_account()
    |> set_financial_transaction_type()
    |> create_multi()
    |> handle_return()
  end

  defp validate_payslip_items(%{payslip_items: []} = context), do: context

  defp validate_payslip_items(%{payslip_items: payslip_items, payslip: payslip} = context) do
    if Enum.all?(payslip_items, &valid_item?(&1, payslip.id)) do
      context
    else
      put_error(context, "payslip items doesn't belong to payslip")
    end
  end

  defp valid_item?(%Item{payslip_id: payslip_id}, payslip_id), do: true
  defp valid_item?(_item, _payslip_id), do: false

  defp validate_due_dates(%{status: :halted} = context), do: context

  defp validate_due_dates(context) do
    case context.due_dates do
      %{payment_advance_date: %Date{}, salary_date: %Date{}} -> context
      _ -> put_error(context, "invalid payments due dates")
    end
  end

  defp get_bank_account(%{status: :halted} = context), do: context

  defp get_bank_account(context) do
    %{registration: registration, payslip: payslip} = context

    case Banks.fetch_entity_active_primary_bank_account(
           payslip.org_id,
           registration.individual_id
         ) do
      {:ok, account} -> %{context | bank_account: account}
      {:error, :not_found} -> %{context | bank_account: :not_found}
    end
  end

  defp set_financial_transaction_type(%{status: :halted} = context), do: context

  defp set_financial_transaction_type(%{bank_account: :not_found} = context),
    do: %{context | financial_transaction_type: :cash}

  defp set_financial_transaction_type(context),
    do: %{context | financial_transaction_type: :bank_transfer}

  defp create_multi(%{status: :halted} = context), do: context

  defp create_multi(context) do
    Multi.new()
    |> Multi.run(:payment_advance, fn _, _ -> create_payment_advance(context) end)
    |> Multi.run(:salary, fn _, _ -> create_salary(context) end)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> %{context | return: changes}
      {:error, _operation, reason, _changes} -> put_error(context, reason)
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

  defp put_error(context, error), do: %{context | status: :halted, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halted, return: {:error, error}}), do: {:error, error}
end
