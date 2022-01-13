defmodule Sig.Finance.Payables.Broadcaster do
  import Sig.Broadcaster

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org

  def subscribe_to_payables(schema), do: subscribe(topics_for(schema))

  def unsubscribe_from_payables(schema), do: unsubscribe(topics_for(schema))

  def broadcast_payables(%Org{} = org, payable_ids) when is_list(payable_ids) do
    payables =
      Payables.list_by(org, payable_ids: payable_ids, preload: Payables.default_preloads())

    broadcast(topics_for(org), {:updated_payables, :by_org, payables})
  end

  def broadcast_payables_for(%Payslip{} = payslip) do
    payables = Payables.list_by(payslip, preload: Payables.default_preloads())

    broadcast(topics_for(payslip), {:updated_payables, {:by_payslip, payslip.id}, payables})
  end

  def broadcast_deleted_payable(%Payable{} = payable) do
    broadcast(topics_for(payable), {:deleted_payable, payable})
  end

  defp topics_for(%Org{} = org) do
    org_payables_topic(org.id)
  end

  defp topics_for(%Payable{} = payable) do
    org_payables_topic(payable.org_id)
  end

  defp topics_for(%Payslip{} = payslip) do
    [
      org_payables_topic(payslip.org_id),
      payslip_payables_topic(payslip.org_id, payslip.id)
    ]
  end

  defp payslip_payables_topic(org_id, payslip_id) do
    "org_id:" <> org_id <> ":payslip_id:" <> payslip_id <> ":payables"
  end

  defp org_payables_topic(org_id) do
    "org_id:" <> org_id <> ":payables"
  end
end
