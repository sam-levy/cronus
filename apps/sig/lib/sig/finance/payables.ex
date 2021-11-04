defmodule Sig.Finance.Payables do
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Repo

  defdelegate create_payable_for_payslip(payslip, attrs), to: PayablesForPayslip, as: :create
  defdelegate delete_payable_for_payslip(payslip, payable), to: PayablesForPayslip, as: :delete

  defdelegate set_payslip_payable_is_auto_adjustable_amount(payslip, payable_id),
    to: PayablesForPayslip,
    as: :set_is_auto_adjustable_amount

  defdelegate create_payable_for_payslip_change(attrs \\ %{}),
    to: PayablesForPayslip,
    as: :create_change

  defdelegate update_payable_for_payslip_change(payable, attrs \\ %{}),
    to: PayablesForPayslip,
    as: :update_change

  defdelegate list_by_payslip(payslip), to: PayablesForPayslip
  defdelegate get_by_payslip(payslip, id), to: PayablesForPayslip

  defdelegate subscribe_to_payables_for_payslip(payslip), to: PayablesForPayslip
  defdelegate unsubscribe_from_payables_for_payslip(payslip), to: PayablesForPayslip
  defdelegate broadcast_payables_for_payslip(payslip), to: PayablesForPayslip

  def authorize(%Payable{} = payable, %{} = attrs) do
    payable
    |> Payable.authorize_changeset(attrs)
    |> Repo.update()
  end

  def unauthorize(%Payable{} = payable) do
    payable
    |> Payable.unauthorize_changeset()
    |> Repo.update()
  end
end
