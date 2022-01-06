defmodule Sig.Finance.Payables.DeleteByIds do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Organizations.Org
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              org: nil,
              return: nil,
              payables: nil,
              payable_ids: nil
  end

  def call(%Org{}, []), do: {:ok, nil}

  def call(%Org{} = org, payable_ids) when is_list(payable_ids) do
    %Context{org: org, payable_ids: payable_ids}
    |> list_payables()
    |> ensure_can_be_deleted()
    |> delete_multi()
    |> handle_return()
  end

  defp list_payables(%{org: org, payable_ids: payable_ids} = context) do
    case Payables.list_by(org, payable_ids: payable_ids, preload: [:payslip_payable]) do
      [] -> halt(context)
      payables -> %{context | payables: payables}
    end
  end

  defp ensure_can_be_deleted(%{status: :halted} = context), do: context

  defp ensure_can_be_deleted(context) do
    if Enum.any?(context.payables, fn
         %{financial_transaction_id: ft_id} when is_binary(ft_id) -> true
         %{authorized_by_id: ab_id} when is_binary(ab_id) -> true
         _ -> false
       end) do
      error(context, "existem pagamentos autorizados ou pagos")
    else
      context
    end
  end

  defp delete_multi(%{status: :halted} = context), do: context

  defp delete_multi(%{org: org, payable_ids: payable_ids} = context) do
    Multi.new()
    |> Multi.delete_all(
      :payslip_payables,
      PayslipPayable
      |> where([pp], pp.org_id == ^org.id)
      |> where([pp], pp.payable_id in ^payable_ids)
    )
    |> Multi.delete_all(
      :payables,
      Payable
      |> where([p], p.org_id == ^org.id)
      |> where([p], p.id in ^payable_ids)
      |> select([p], p)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{payables: {_, payables}}} -> %{context | return: payables}
      {:error, _operation, reason, _changes} -> error(context, reason)
    end
  end

  defp halt(context), do: %{context | status: :halted}

  defp error(context, error), do: %{context | status: :halted, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halted, return: nil}), do: {:ok, nil}
  defp handle_return(%{status: :halted, return: {:error, error}}), do: {:error, error}
end
