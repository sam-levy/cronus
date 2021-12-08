defmodule Sig.HR.Payslips.Delete do
  alias Ecto.Multi

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Groups
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org
  alias Sig.Repo

  def call(%Org{} = org, %Payslip{} = payslip) do
    Multi.new()
    |> Multi.run(:delete_payslip, fn _, _ -> Payslips.delete_by_ids(org, [payslip.id]) end)
    |> Multi.run(:delete_group, fn _, _ -> maybe_delete_group(payslip) end)
    |> Repo.transaction()
    |> handle_return()
  end

  defp maybe_delete_group(payslip) do
    with {:ok, group} <- Groups.fetch_by(org_id: payslip.org_id, id: payslip.group_id),
         [] <- Payslips.list_by(group),
         {:ok, group} <- Groups.delete(group) do
      {:ok, group}
    else
      {:error, _} = error -> error
      [_ | _] -> {:ok, nil}
    end
  end

  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}

  defp handle_return({:ok, %{delete_group: group, delete_payslip: [payslip]}}) do
    Payslips.broadcast_deleted_payslip(payslip)
    broadcast_deleted_group(group)

    {:ok, payslip}
  end

  defp broadcast_deleted_group(nil), do: nil

  defp broadcast_deleted_group(group) when is_struct(group) do
    Groups.broadcast_deleted_group(group)
  end
end
