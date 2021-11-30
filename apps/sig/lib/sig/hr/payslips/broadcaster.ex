defmodule Sig.HR.Payslips.Broadcaster do
  import Sig.Broadcaster

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Registration

  def unsubscribe_from_payslip(%Payslip{} = payslip), do: unsubscribe(topic(payslip))

  def subscribe_to_payslips(schema), do: subscribe(topic(schema))

  def broadcast_new_payslip(%Payslip{} = payslip, opts \\ []) do
    broadcast(topic(payslip), {:new_payslip, handle_opts(payslip, opts)})
  end

  def broadcast_updated_payslip(payslip, old_payslip, opts \\ [])

  def broadcast_updated_payslip(%Payslip{} = payslip, %Payslip{} = old_payslip, opts) do
    if payslip.group_id != old_payslip.group_id do
      broadcast(topic(old_payslip), {:updated_payslip, handle_opts(payslip, opts)})
      broadcast(topic(payslip), {:updated_payslip, handle_opts(payslip, opts)})
    else
      broadcast(topic(payslip), {:updated_payslip, handle_opts(payslip, opts)})
    end
  end

  def broadcast_updated_payslip(%Payslip{} = payslip, _, opts) do
    broadcast(topic(payslip), {:updated_payslip, handle_opts(payslip, opts)})
  end

  def broadcast_deleted_payslip(%Payslip{} = payslip) do
    broadcast(topic(payslip), {:deleted_payslip, payslip})
  end

  defp handle_opts(payslip, opts) do
    if Keyword.get(opts, :refetch, false) do
      Payslips.get_by([org_id: payslip.org_id, id: payslip.id], opts)
    else
      payslip
    end
  end

  defp topic(%Payslip{} = payslip) do
    [
      "registration_id:" <> payslip.registration_id <> ":payslips",
      "group_id:" <> payslip.group_id <> ":payslips"
    ]
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":payslips"
  end

  defp topic(%Group{} = group) do
    "group_id:" <> group.id <> ":payslips"
  end
end
