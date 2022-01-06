defmodule Sig.Finance.Payables.Broadcaster do
  import Sig.Broadcaster

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org

  @preloads [:payslip, :employee, :employee_registration_company]

  # Add missing tests

  def subscribe_to_payables(schema), do: subscribe(topic(schema))

  def subscribe_to_payables(%Org{} = org, due_date_start, due_date_end) do
    subscribe(topic(org, due_date_start, due_date_end))
  end

  def unsubscribe_from_payables(schema), do: unsubscribe(topic(schema))

  def unsubscribe_from_payables(%Org{} = org, due_date_start, due_date_end) do
    unsubscribe(topic(org, due_date_start, due_date_end))
  end

  def broadcast_new_payables(%Payslip{} = payslip) do
    payables = Payables.list_by(payslip, preload: @preloads)

    Enum.each(payables, &broadcast(topic(&1), {:new_payable, &1}))
  end

  def broadcast_new_payable(%Payable{} = payable) do
    payable = Payables.get_by([id: payable.id, org_id: payable.org_id], preload: @preloads)

    broadcast(topic(payable), {:new_payable, payable})
  end

  def broadcast_updated_payables(%Payslip{} = payslip) do
    payables = Payables.list_by(payslip, preload: @preloads)

    broadcast(topic(payslip), {:updated_payables, payables})

    Enum.each(payables, &broadcast(topic(&1), {:updated_payable, &1}))
  end

  def broadcast_deleted_payable(%Payable{} = payable) do
    broadcast(topic(payable), {:deleted_payable, payable})
  end

  defp topic(%Payslip{} = payslip), do: "payslip_id:" <> payslip.id <> ":payables"

  defp topic(%Payable{} = payable) do
    org_due_date_topic(payable.org_id, Date.to_iso8601(payable.due_date))
  end

  defp topic(%Org{} = org, due_date_start, due_date_end) do
    due_date_start
    |> Date.range(due_date_end)
    |> Enum.map(&org_due_date_topic(org.id, Date.to_iso8601(&1)))
  end

  defp org_due_date_topic(org_id, due_date) do
    "org_id:" <> org_id <> ":due_date:" <> due_date <> ":payables"
  end
end
