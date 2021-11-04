defmodule Sig.Finance.Payables.PayablesForPayslip do
  import Ecto.Query

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.Create
  alias Sig.Finance.Payables.PayablesForPayslip.Delete
  alias Sig.Finance.Payables.PayablesForPayslip.Update
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defdelegate create(payslip, attrs), to: Create, as: :call
  defdelegate delete(payslip, payable), to: Delete, as: :call
  defdelegate update(payslip, payable, attrs), to: Update, as: :call
  defdelegate set_is_auto_adjustable_amount(payslip, payable_id), to: PayslipPayables

  defdelegate update_auto_adjustable_amount_payable(payslip),
    to: UpdateAutoAdjustableAmountPayable,
    as: :call

  def create_change(%{} = attrs \\ %{}) do
    Payable.create_changeset(attrs)
  end

  def update_change(%Payable{} = payable, %{} = attrs \\ %{}) do
    Payable.update_changeset(payable, attrs)
  end

  def list_by_payslip(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> order_by(:due_date)
    |> Repo.all()
  end

  def get_by_payslip(%Payslip{} = payslip, id) when is_binary(id) do
    payslip
    |> query_by_payslip()
    |> where(id: ^id)
    |> Repo.one()
  end

  def subscribe_to_payables_for_payslip(%Payslip{} = payslip) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(payslip))
  end

  def unsubscribe_from_payables_for_payslip(%Payslip{} = payslip) do
    Phoenix.PubSub.unsubscribe(Sig.PubSub, topic(payslip))
  end

  def broadcast_payables_for_payslip(%Payslip{} = payslip) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(payslip),
      {:updated_payables_for_payslip, list_by_payslip(payslip)}
    )
  end

  defp topic(%Payslip{} = payslip), do: "payslip_id:" <> payslip.id <> ":payables"

  def query_by_payslip(%Payslip{} = payslip) do
    Payable
    |> join(:left, [payable], payslip_payable in PayslipPayable,
      on: payslip_payable.payable_id == payable.id and payslip_payable.org_id == ^payslip.org_id,
      as: :payslip_payable
    )
    |> preload([payable, payslip_payable: payslip_payable], payslip_payable: payslip_payable)
    |> where(
      [_payable, payslip_payable: payslip_payable],
      payslip_payable.payslip_id == ^payslip.id
    )
    |> where(org_id: ^payslip.org_id)
    |> where(target: :payslip)
  end
end
