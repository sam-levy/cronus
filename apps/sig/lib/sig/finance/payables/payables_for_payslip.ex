defmodule Sig.Finance.Payables.PayablesForPayslip do
  import Ecto.Changeset, only: [add_error: 3]
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks
  alias Sig.Finance.Payables.Payable
  alias Sig.Finance.Payables.PayablesForPayslip.Authorizer
  alias Sig.Finance.Payables.PayablesForPayslip.Create
  alias Sig.Finance.Payables.PayablesForPayslip.CreateStandardPayables
  alias Sig.Finance.Payables.PayablesForPayslip.Delete
  alias Sig.Finance.Payables.PayablesForPayslip.Update
  alias Sig.Finance.Payables.PayablesForPayslip.AutoAdjustableAmountHandler
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables
  alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable
  alias Sig.Finance.Payables.PayablesForPayslip.UpdateAutoAdjustableAmountPayable
  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Registration
  alias Sig.Repo

  defdelegate create(payslip, attrs, opts \\ []), to: Create, as: :call

  def create_payables(%Registration{} = registration, %Payslip{} = payslip, items, opts \\ [])
      when is_list(items) do
    case Keyword.get(opts, :payables_attrs) do
      %{type: :standard, due_dates: due_dates} ->
        CreateStandardPayables.call(registration, payslip, items, due_dates)

      nil ->
        {:ok, nil}

      _ ->
        {:error, "invalid payables attrs"}
    end
  end

  defdelegate delete(payslip, payable), to: Delete, as: :call
  defdelegate update(payslip, payable, attrs), to: Update, as: :call
  defdelegate set_as_auto_adjustable_amount(payslip, payable), to: AutoAdjustableAmountHandler
  defdelegate unset_as_auto_adjustable_amount(payslip, payable), to: PayslipPayables
  defdelegate authorize(payslip, payable, user), to: Authorizer
  defdelegate unauthorize(payslip), to: Authorizer

  defdelegate update_auto_adjustable_amount_payable(payslip, opts \\ []),
    to: UpdateAutoAdjustableAmountPayable,
    as: :call

  defdelegate list_payslip_payables_by_payslip(payslip), to: PayslipPayables, as: :list_by_payslip

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
    |> preload_authorized_by()
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch_by_payslip(%Payslip{} = payslip, id) when is_binary(id) do
    case get_by_payslip(payslip, id) do
      %Payable{} = payable -> {:ok, payable}
      nil -> {:error, :not_found}
    end
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

  def sum_non_adjustable_payables_amounts(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> where([payslip_payable: payslip_payable], not payslip_payable.is_auto_adjustable_amount)
    |> handle_amount_sum()
  end

  def sum_non_adjustable_payables_amounts(%Payslip{} = payslip, %Payable{} = payable) do
    payslip
    |> query_by_payslip()
    |> where(
      [payslip_payable: payslip_payable],
      not payslip_payable.is_auto_adjustable_amount and
        payslip_payable.payable_id != ^payable.id
    )
    |> handle_amount_sum()
  end

  defp handle_amount_sum(queryable) do
    queryable
    |> Repo.aggregate(:sum, :amount)
    |> case do
      %Money{} = sum -> sum
      nil -> Money.new(0)
    end
  end

  def validate_credit_bank_account(
        %Ecto.Changeset{changes: %{credit_bank_account_id: account_id}} = changeset,
        payslip
      )
      when is_binary(account_id) do
    entity =
      from(entity in Entity, as: :entity)
      |> join(:left, [entity: e], r in Registration,
        on: r.individual_id == e.id,
        as: :registration
      )
      |> join(:left, [registration: r], p in Payslip, on: p.registration_id == r.id, as: :payslip)
      |> where([payslip: p], p.id == ^payslip.id)
      |> where([entity: e], e.org_id == ^payslip.org_id)
      |> Repo.one()

    valid_account_ids =
      entity
      |> Banks.list_active_bank_accounts_by_entity()
      |> Enum.map(& &1.id)

    if changeset.changes.credit_bank_account_id in valid_account_ids do
      {:ok, nil}
    else
      {:error, add_error(changeset, :credit_bank_account_id, "isn't related to the individual")}
    end
  end

  def validate_credit_bank_account(_changeset, _payslip), do: {:ok, nil}

  def validate_check_bank_account(
        %Ecto.Changeset{changes: %{check_bank_account_id: account_id}} = changeset,
        payslip
      )
      when is_binary(account_id) do
    entity =
      from(entity in Entity, as: :entity)
      |> join(:left, [entity: e], r in Registration,
        on: r.registered_at_id == e.id,
        as: :registration
      )
      |> join(:left, [registration: r], p in Payslip, on: p.registration_id == r.id, as: :payslip)
      |> where([payslip: p], p.id == ^payslip.id)
      |> where([entity: e], e.org_id == ^payslip.org_id)
      |> Repo.one()

    valid_account_ids =
      entity
      |> Banks.list_active_bank_accounts_by_entity()
      |> Enum.map(& &1.id)

    if changeset.changes.check_bank_account_id in valid_account_ids do
      {:ok, nil}
    else
      {:error, add_error(changeset, :check_bank_account_id, "isn't related to the company")}
    end
  end

  def validate_check_bank_account(_changeset, _payslip), do: {:ok, nil}

  def query_by_payslip(%Payslip{} = payslip) do
    from(payable in Payable, as: :payable)
    |> join(:left, [payable: payable], payslip_payable in PayslipPayable,
      on: payslip_payable.payable_id == payable.id and payslip_payable.org_id == ^payslip.org_id,
      as: :payslip_payable
    )
    |> preload([payslip_payable: payslip_payable], payslip_payable: payslip_payable)
    |> where([payslip_payable: payslip_payable], payslip_payable.payslip_id == ^payslip.id)
    |> where(org_id: ^payslip.org_id)
    |> where(target: :payslip)
  end

  defp preload_authorized_by(queryable) do
    queryable
    |> join(:left, [payable: payable], authorized_by in assoc(payable, :authorized_by),
      as: :authorized_by
    )
    |> preload([authorized_by: authorized_by], authorized_by: authorized_by)
  end
end
