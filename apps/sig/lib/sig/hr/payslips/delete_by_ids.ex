defmodule Sig.HR.Payslips.DeleteByIds do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.Organizations.Org
  alias Sig.Finance
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defmodule Context do
    defstruct status: :ok,
              org: nil,
              return: nil,
              payslips: nil,
              item_ids: nil,
              payslip_ids: nil,
              payable_ids: nil
  end

  def call(%Org{}, []), do: {:ok, nil}

  def call(%Org{} = org, payslip_ids) when is_list(payslip_ids) do
    %Context{org: org, payslip_ids: payslip_ids}
    |> list_payslips()
    |> put_ids()
    |> delete_multi()
    |> handle_return()
  end

  defp list_payslips(%{org: org, payslip_ids: payslip_ids} = context) do
    case Payslips.list_by_ids(org, payslip_ids, preload: [:items, :payslip_payables, :overtimes]) do
      [] -> halt(context)
      payslips -> %{context | payslips: payslips}
    end
  end

  defp put_ids(%{status: :halted} = context), do: context

  defp put_ids(%{payslips: payslips} = context) do
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
      {:error, message} -> error(context, message)
      acc -> struct(context, acc)
    end
  end

  defp delete_multi(%{status: :halted} = context), do: context

  defp delete_multi(context) do
    %{org: org, payable_ids: payable_ids, item_ids: item_ids, payslip_ids: payslip_ids} = context

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
      {:ok, %{payslips: {_, payslips}}} -> %{context | return: payslips}
      {:error, _operation, reason, _changes} -> error(context, reason)
    end
  end

  defp halt(context), do: %{context | status: :halted}

  defp error(context, error), do: %{context | status: :halted, return: {:error, error}}

  defp handle_return(%{status: :ok, return: return}), do: {:ok, return}
  defp handle_return(%{status: :halted, return: nil}), do: {:ok, nil}
  defp handle_return(%{status: :halted, return: {:error, error}}), do: {:error, error}
end
