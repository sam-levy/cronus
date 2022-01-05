defmodule Sig.Finance.Payables.Broadcaster do
  import Sig.Broadcaster

  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Payslip

  def subscribe_to_payables(schema), do: subscribe(topic(schema))

  def unsubscribe_from_payables(schema), do: unsubscribe(topic(schema))

  def broadcast_payables(%Payslip{} = payslip) do
    broadcast(
      topic(payslip),
      {:updated_payables, PayablesForPayslip.list_by_payslip(payslip)}
    )
  end

  defp topic(%Payslip{} = payslip), do: "payslip_id:" <> payslip.id <> ":payables"
end
