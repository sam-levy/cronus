defmodule Sig.Finance.Payables do
  use Sig.Preloader,
    payable: [
      :payslip_payable,
      :financial_transaction,
      :authorized_by,
      :check_debit_bank_account,
      :credit_bank_account
    ]

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

  def get_by(attrs), do: Repo.get_by(Payable, attrs)

  def set_changeset_financial_transaction_type(
        %Ecto.Changeset{data: %Payable{}} = changeset,
        financial_transaction_type
      )
      when is_atom(financial_transaction_type) do
    put_change(changeset, :financial_transaction_type, financial_transaction_type)
  end

  def list(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(opts)
    |> preload_underlying(opts)
    |> filter_by_due_date(opts)
    |> filter_by_payable_ids(opts)
    |> filter_authorized(opts)
    |> order()
    |> Repo.all()
  end

  defp query_by(%Org{} = org) do
    init_query() |> where(org_id: ^org.id)
  end

  defp init_query, do: from(p in Payable, as: :payable)

  defp filter_by_due_date(queryable, opts) do
    case Keyword.get(opts, :due_date, nil) do
      nil ->
        queryable

      [period_start: period_start, period_end: period_end] ->
        where(queryable, [payable: p], p.due_date >= ^period_start and p.due_date <= ^period_end)
    end
  end

  defp filter_by_payable_ids(queryable, opts) do
    case Keyword.get(opts, :payable_ids, nil) do
      nil ->
        queryable

      payable_ids when is_list(payable_ids) ->
        where(queryable, [payable: p], p.id in ^payable_ids)
    end
  end

  defp filter_authorized(queryable, opts) do
    if Keyword.get(opts, :authorized_by, false) do
      where(queryable, [payable: p], not is_nil(p.authorized_by_id))
    else
      queryable
    end
  end

  defp preload_underlying(queryable, opts) do
    if Keyword.get(opts, :preload_underlying, false) do
      queryable
      |> join(:left, [payable: p], payable in assoc(p, :payslip), as: :payslip)
      |> preload([payslip: payslip], payslip: payslip)
    else
      queryable
    end
  end

  defp order(queryable) do
    order_by(queryable, [:due_date, :target, :description])
  end
end
