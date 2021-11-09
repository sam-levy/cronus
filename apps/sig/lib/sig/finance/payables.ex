defmodule Sig.Finance.Payables do
  import Ecto.Changeset, only: [put_change: 3]

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Repo

  defdelegate create_payable_for_payslip(payslip, attrs, opts \\ []),
    to: PayablesForPayslip,
    as: :create

  defdelegate update_payable_for_payslip(payslip, payable, attrs),
    to: PayablesForPayslip,
    as: :update

  defdelegate delete_payable_for_payslip(payslip, payable), to: PayablesForPayslip, as: :delete

  defdelegate create_payable_for_payslip_change(attrs \\ %{}),
    to: PayablesForPayslip,
    as: :create_change

  defdelegate update_payable_for_payslip_change(payable, attrs \\ %{}),
    to: PayablesForPayslip,
    as: :update_change

  defdelegate set_payable_for_payslip_as_auto_adjustable(payslip, payable),
    to: PayablesForPayslip,
    as: :set_as_auto_adjustable_amount

  defdelegate unset_payable_for_payslip_as_auto_adjustable(payslip, payable),
    to: PayablesForPayslip,
    as: :unset_as_auto_adjustable_amount

  defdelegate list_by_payslip(payslip), to: PayablesForPayslip
  defdelegate get_by_payslip(payslip, id), to: PayablesForPayslip
  defdelegate fetch_by_payslip(payslip, id), to: PayablesForPayslip
  defdelegate subscribe_to_payables_for_payslip(payslip), to: PayablesForPayslip
  defdelegate unsubscribe_from_payables_for_payslip(payslip), to: PayablesForPayslip
  defdelegate broadcast_payables_for_payslip(payslip), to: PayablesForPayslip

  def set_changeset_method(%Ecto.Changeset{data: %Payable{}} = changeset, method)
      when is_atom(method) do
    put_change(changeset, :method, method)
  end

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
