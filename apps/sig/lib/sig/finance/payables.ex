defmodule Sig.Finance.Payables do
  use Sig.Preloader, payable: [:payslip_payable]

  import Ecto.Changeset, only: [put_change: 3]

  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.Finance.Payables.DeleteByIds
  alias Sig.Organizations.Org
  alias Sig.Repo

  defdelegate delete_by_ids(org, ids), to: DeleteByIds, as: :call

  defdelegate create_payable_for_payslip(payslip, attrs, opts \\ []),
    to: PayablesForPayslip,
    as: :create

  defdelegate create_payables_for_payslip(registration, payslip, items, opts \\ []),
    to: PayablesForPayslip,
    as: :create_payables

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

  defdelegate authorize_payable_for_payslip(payslip, payable, user),
    to: PayablesForPayslip,
    as: :authorize

  defdelegate unauthorize_payable_for_payslip(payable), to: PayablesForPayslip, as: :unauthorize

  defdelegate list_payslip_payables_by_payslip(payslip), to: PayablesForPayslip

  def list_by_ids(%Org{} = org, payable_ids, opts \\ []) when is_list(payable_ids) do
    from(p in Payable, as: :payable)
    |> where([payable: p], p.org_id == ^org.id)
    |> where([payable: p], p.id in ^payable_ids)
    |> shallow_preload(opts)
    |> Repo.all()
  end

  def get_by(attrs), do: Repo.get_by(Payable, attrs)

  def set_changeset_financial_transaction_type(
        %Ecto.Changeset{data: %Payable{}} = changeset,
        financial_transaction_type
      )
      when is_atom(financial_transaction_type) do
    put_change(changeset, :financial_transaction_type, financial_transaction_type)
  end
end
