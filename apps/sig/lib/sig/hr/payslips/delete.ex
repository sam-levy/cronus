defmodule Sig.HR.Payslips.Delete do
  alias Ecto.Multi

  alias Sig.Finance
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @closed_payslip_message "can't delete a closed payslip"
  @payslip_with_items_message "can't delete a payslip with items"
  @payslip_with_payables_message "can't delete a payslip with payables"

  def call(%Payslip{is_closed: true}) do
    {:error, @closed_payslip_message}
  end

  def call(%Payslip{is_closed: false} = payslip) do
    Multi.new()
    |> Multi.run(:ensure_can_be_deleted, fn _, _ -> ensure_can_be_deleted(payslip) end)
    |> Multi.run(:ensure_has_no_items, fn _, _ -> ensure_has_no_items(payslip) end)
    |> Multi.run(:ensure_has_no_payables, fn _, _ -> ensure_has_no_payables(payslip) end)
    |> Multi.delete(:delete, fn %{ensure_can_be_deleted: payable} -> payable end)
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{delete: payslip}} -> {:ok, payslip}
    end
  end

  defp ensure_can_be_deleted(%Payslip{id: id, org_id: org_id}) do
    case Payslips.get_by(id: id, org_id: org_id) do
      %{is_closed: false, amount: %Money{amount: 0}} = payslip -> {:ok, payslip}
      %{is_closed: true} -> {:error, @closed_payslip_message}
      %{amount: %Money{amount: amount}} when amount > 0  -> {:error, @payslip_with_items_message}
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
      _ -> {:error, @payslip_with_payables_message}
    end
  end
end
