defmodule Sig.Finance.Payables do
  use Sig.Preloader,
    payable: [
      :employee,
      :employee_registration_company,
      :payslip,
      :payslip_payable,
      :financial_transaction,
      :authorized_by,
      :check_debit_bank_account,
      :credit_bank_account
    ]

  import Ecto.Changeset, only: [put_change: 3]

  alias Sig.Finance.FinancialTransactions.FinancialTransaction
  alias Sig.Finance.Payables.Broadcaster
  alias Sig.Finance.Payables.DeleteByIds
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org
  alias Sig.Repo

  @default_preloads [
    :payslip,
    :employee,
    :payslip_payable,
    :credit_bank_account,
    :financial_transaction,
    :employee_registration_company
  ]

  defdelegate subscribe_to_payables(schema), to: Broadcaster
  defdelegate unsubscribe_from_payables(schema), to: Broadcaster
  defdelegate broadcast_payables(org, payable_ids), to: Broadcaster
  defdelegate broadcast_payables_for(schema), to: Broadcaster
  defdelegate broadcast_deleted_payable(payable), to: Broadcaster

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

  defdelegate authorize_payable_for_payslip(payslip, payable, user),
    to: PayablesForPayslip,
    as: :authorize

  defdelegate unauthorize_payable_for_payslip(payable), to: PayablesForPayslip, as: :unauthorize

  def payable_overdue?(%Payable{financial_transaction_id: nil} = payable, %Date{} = overdue_at) do
    case Date.compare(payable.due_date, overdue_at) do
      :lt -> true
      _gt_or_eq -> false
    end
  end

  def payable_overdue?(%Payable{}, %Date{}), do: false

  def default_preloads, do: @default_preloads

  def set_changeset_financial_transaction_type(
        %Ecto.Changeset{data: %Payable{}} = changeset,
        financial_transaction_type
      )
      when is_atom(financial_transaction_type) do
    put_change(changeset, :financial_transaction_type, financial_transaction_type)
  end

  def get(%Payslip{} = payslip, id, opts \\ []) when is_binary(id) do
    payslip
    |> query_by()
    |> where(id: ^id)
    |> shallow_preload(opts)
    |> Repo.one()
  end

  def fetch(%Payslip{} = payslip, id, opts \\ []) when is_binary(id) do
    case get(payslip, id, opts) do
      %Payable{} = payable -> {:ok, payable}
      nil -> {:error, :not_found}
    end
  end

  def get_by(attrs, opts \\ []) do
    init_query()
    |> where(^attrs)
    |> shallow_preload(opts)
    |> Repo.one()
  end

  def list_by(schema, opts \\ [])
  def list_by(%Org{} = schema, opts), do: do_list_by(schema, opts)
  def list_by(%Payslip{} = schema, opts), do: do_list_by(schema, opts)
  def list_by(%FinancialTransaction{} = schema, opts), do: do_list_by(schema, opts)

  defp do_list_by(schema, opts) do
    schema
    |> query_by()
    |> shallow_preload(opts)
    |> filter_by_due_date(opts)
    |> filter_by_payable_ids(opts)
    |> filter_authorized(opts)
    |> order()
    |> Repo.all()
  end

  def init_query, do: from(p in Payable, as: :payable)

  defp query_by(%Org{} = org) do
    init_query() |> where(org_id: ^org.id)
  end

  defp query_by(%Payslip{} = payslip) do
    PayablesForPayslip.query_by_payslip(payslip)
  end

  defp query_by(%FinancialTransaction{} = financial_transaction) do
    init_query()
    |> where(org_id: ^financial_transaction.org_id)
    |> where(financial_transaction_id: ^financial_transaction.id)
  end

  defp filter_by_due_date(queryable, opts) do
    case Keyword.get(opts, :due_date, nil) do
      nil ->
        queryable

      [period_start: period_start, period_end: period_end, overdue_at: overdue_at] ->
        queryable
        |> where([payable: p], p.due_date >= ^period_start and p.due_date <= ^period_end)
        |> or_where(
          [payable: p],
          is_nil(p.financial_transaction_id) and
            p.due_date < ^overdue_at and
            p.due_date < ^period_start
        )

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
    case Keyword.get(opts, :authorized) do
      true -> where(queryable, [payable: p], not is_nil(p.authorized_by_id))
      false -> where(queryable, [payable: p], is_nil(p.authorized_by_id))
      nil -> queryable
    end
  end

  # Alterar testes
  defp order(queryable) do
    order_by(queryable, [:due_date, :description])
  end
end
