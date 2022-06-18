defmodule Sig.Finance.Payables.DeleteByIds do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Organizations.Org
  alias Sig.Repo

  def call(%Org{}, []), do: {:ok, nil}

  def call(%Org{} = org, payable_ids) when is_list(payable_ids) do
    %{org: org, payable_ids: payable_ids}
    |> Extep.new()
    |> Extep.run(&list_payables/1, :payables)
    |> Extep.run(&ensure_can_be_deleted/1)
    |> Extep.run(&delete_multi/1, :deleted_payables)
    |> Extep.return(:deleted_payables)
  end

  defp list_payables(%{org: org, payable_ids: payable_ids}) do
    case Payables.list_by(org, payable_ids: payable_ids, preload: [:payslip_payable]) do
      [] -> {:error, nil}
      payables -> {:ok, payables}
    end
  end

  defp ensure_can_be_deleted(context) do
    if Enum.any?(context.payables, fn
         %{financial_transaction_id: ft_id} when is_binary(ft_id) -> true
         %{authorized_by_id: ab_id} when is_binary(ab_id) -> true
         _ -> false
       end) do
      {:error, "existem pagamentos autorizados ou pagos"}
    else
      :ok
    end
  end

  defp delete_multi(%{org: org, payable_ids: payable_ids}) do
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
      {:ok, %{payables: {_, payables}}} -> {:ok, payables}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end
end
