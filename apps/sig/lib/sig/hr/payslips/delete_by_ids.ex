defmodule Sig.HR.Payslips.DeleteByIds do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Organizations.Org
  alias Sig.Finance
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  def call(%Org{}, []), do: {:ok, nil}

  def call(%Org{} = org, payslip_ids) when is_list(payslip_ids) do
    %{org: org, payslip_ids: payslip_ids}
    |> Extep.new()
    |> Extep.run(&list_payslips/1, :payslips)
    |> Extep.run(&handle_resource_ids/1, :resource_ids_to_delete)
    |> Extep.return(&delete_multi/1)
  end

  defp list_payslips(%{org: org, payslip_ids: payslip_ids}) do
    case Payslips.list_by_ids(org, payslip_ids, preload: [:items, :payslip_payables, :overtimes]) do
      [] -> :halt
      payslips -> {:ok, payslips}
    end
  end

  defp handle_resource_ids(%{payslips: payslips}) do
    payslips
    |> Enum.reduce_while(%{}, fn
      %{is_closed: true}, _acc ->
        {:halt, {:error, "Existem holerites fechados"}}

      %{overtimes: [_ | _]}, _acc ->
        {:halt, {:error, "Existem horas extras associadas a holerites"}}

      payslip, acc ->
        acc =
          acc
          |> Sig.Map.flat_put(:payable_ids, Enum.map(payslip.payslip_payables, & &1.payable_id))
          |> Sig.Map.flat_put(:item_ids, Enum.map(payslip.items, & &1.id))
          |> Sig.Map.flat_put(:payslip_ids, payslip.id)

        {:cont, acc}
    end)
    |> case do
      {:error, message} -> {:error, message}
      acc -> {:ok, acc}
    end
  end

  defp delete_multi(context) do
    %{
      org: org,
      resource_ids_to_delete: %{
        payable_ids: payable_ids,
        item_ids: item_ids,
        payslip_ids: payslip_ids
      }
    } = context

    Multi.new()
    |> Multi.run(:payables, fn _, _ -> Finance.Payables.delete_by_ids(org, payable_ids) end)
    |> Multi.delete_all(
      :items,
      Item
      |> where([i], i.org_id == ^org.id)
      |> where([i], i.id in ^item_ids)
    )
    |> Multi.delete_all(
      :payslips,
      Payslip
      |> where([p], p.org_id == ^org.id)
      |> where([p], p.id in ^payslip_ids)
      |> select([p], p)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{payslips: {_, payslips}, payables: payables}} ->
        {:ok, %{payslips: payslips, payables: payables}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end
end
