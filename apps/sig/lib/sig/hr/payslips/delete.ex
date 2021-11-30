defmodule Sig.HR.Payslips.Delete do
  alias Ecto.Multi

  alias Sig.Finance
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Groups
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Overtimes
  alias Sig.Repo

  @closed_payslip_message "can't delete a closed payslip"
  @payslip_with_items_message "can't delete a payslip with items"

  def call(%Payslip{is_closed: true}) do
    {:error, @closed_payslip_message}
  end

  def call(%Payslip{is_closed: false} = payslip) do
    Multi.new()
    |> Multi.run(:ensure_can_be_deleted, fn _, _ -> ensure_can_be_deleted(payslip) end)
    |> Multi.run(:ensure_has_no_items, fn _, _ -> ensure_has_no_items(payslip) end)
    |> Multi.run(:ensure_has_no_payables, fn _, _ -> ensure_has_no_payables(payslip) end)
    |> Multi.run(:ensure_has_no_overtimes, fn _, _ -> ensure_has_no_overtimes(payslip) end)
    |> Multi.delete(:delete_payslip, fn %{ensure_can_be_deleted: payslip} -> payslip end)
    |> Multi.run(:delete_group, fn _, _ -> maybe_delete_group(payslip) end)
    |> Repo.transaction()
    |> handle_return()
  end

  defp ensure_can_be_deleted(%Payslip{id: id, org_id: org_id}) do
    case Payslips.get_by([id: id, org_id: org_id], preload: :org) do
      %{is_closed: false, amount: %Money{amount: 0}} = payslip -> {:ok, payslip}
      %{is_closed: true} -> {:error, @closed_payslip_message}
      %{amount: %Money{amount: amount}} when amount > 0 -> {:error, @payslip_with_items_message}
    end
  end

  defp ensure_has_no_items(payslip) do
    case Items.list_by_payslip(payslip) do
      [] -> {:ok, nil}
      _ -> {:error, @payslip_with_items_message}
    end
  end

  defp ensure_has_no_payables(payslip) do
    case Finance.list_payslip_payables_by_payslip(payslip) do
      [] -> {:ok, nil}
      _ -> {:error, "can't delete a payslip with payables"}
    end
  end

  defp ensure_has_no_overtimes(payslip) do
    case Overtimes.list_by_payslip(payslip) do
      [] -> {:ok, nil}
      _ -> {:error, "can't delete a payslip with overtimes"}
    end
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

  defp handle_return({:ok, %{delete_payslip: payslip} = changes}) do
    broadcast_deleted_group(changes)

    {:ok, payslip}
  end

  defp broadcast_deleted_group(%{delete_group: group, ensure_can_be_deleted: payslip})
       when is_struct(group) do
    Groups.broadcast_deleted_group(payslip.org, group)
  end

  defp broadcast_deleted_group(_changes), do: nil
end
