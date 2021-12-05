defmodule Sig.HR.Payslips do
  use Sig.Preloader, payslip: [:org, :registration]

  import Ecto.Query

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Payslips.BatchCreator
  alias Sig.HR.Payslips.Broadcaster
  alias Sig.HR.Payslips.CreateFromModel
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.Mutator
  alias Sig.HR.Payslips.Delete
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defdelegate create(registration, attrs), to: Mutator, as: :create
  defdelegate update(payslip, attrs), to: Mutator, as: :update
  defdelegate delete(payslip), to: Delete, as: :call
  defdelegate batch_create(org, attrs, opts \\ []), to: BatchCreator, as: :create
  defdelegate verify_batch_create(org, attrs), to: BatchCreator, as: :verify

  defdelegate create_from_model(registration, attrs, opts \\ []),
    to: CreateFromModel,
    as: :call

  defdelegate subscribe_to_payslips(schema), to: Broadcaster
  defdelegate broadcast_new_payslip(payslip, opts \\ []), to: Broadcaster
  defdelegate broadcast_updated_payslip(updated_payslip, old_payslip, opts \\ []), to: Broadcaster
  defdelegate broadcast_deleted_payslip(payslip), to: Broadcaster
  defdelegate unsubscribe_from_payslip(payslip), to: Broadcaster

  def create_change(%{} = attrs \\ %{}) do
    Payslip.create_changeset(attrs)
  end

  def update_change(%Payslip{} = payslip, %{} = attrs \\ %{}) do
    Payslip.update_changeset(payslip, attrs)
  end

  def list_by(schema, opts \\ [])

  def list_by(%Registration{} = registration, opts) do
    registration
    |> query_by()
    |> order_by(desc: :start_date)
    |> apply_limit(opts)
    |> Repo.all()
  end

  def list_by(%Group{} = group, opts) do
    group
    |> query_by()
    |> preload_registration(opts)
    |> Repo.all()
  end

  def get(schema, id, opts \\ [])

  def get(%Registration{} = registration, id, _opts) when is_binary(id) do
    registration
    |> query_by()
    |> where(id: ^id)
    |> shallow_preload(:org)
    |> Repo.one()
  end

  def get(%Group{} = group, id, opts) when is_binary(id) do
    group
    |> query_by()
    |> preload_registration(opts)
    |> where(id: ^id)
    |> Repo.one()
  end

  def get_by(attrs, opts \\ []) do
    init_query()
    |> where(^attrs)
    |> shallow_preload(opts)
    |> preload_registration(opts)
    |> Repo.one()
  end

  def toggle_is_closed(%Payslip{} = payslip) do
    payslip
    |> Payslip.update_is_closed_changeset(%{is_closed: !payslip.is_closed})
    |> Repo.update()
  end

  def update_payslip_amount(%Payslip{} = payslip, items) when is_list(items) do
    items
    |> Enum.filter(&(&1.payslip_id == payslip.id))
    |> calculate_payslip_items_amount()
    |> case do
      %Money{amount: amount} when amount < 0 ->
        {:error, "payslip amount can't be negative"}

      %Money{amount: amount} when amount == payslip.amount.amount ->
        {:ok, payslip}

      %Money{amount: amount} ->
        payslip
        |> Payslip.update_amount_changeset(%{amount: amount})
        |> Repo.update()
    end
  end

  def calculate_payslip_items_amount([]), do: Money.new(0)

  def calculate_payslip_items_amount(items) do
    Money.subtract(Sig.sum_by(:credit, items), Sig.sum_by(:debit, items))
  end

  defp query_by(%Registration{} = registration) do
    init_query()
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp query_by(%Group{} = group) do
    init_query()
    |> where(org_id: ^group.org_id)
    |> where(group_id: ^group.id)
  end

  defp init_query, do: from(p in Payslip, as: :payslip)

  defp apply_limit(queryable, opts) do
    case Keyword.get(opts, :limit, nil) do
      nil -> queryable
      limit -> limit(queryable, ^limit)
    end
  end

  defp preload_registration(queryable, opts) do
    if Keyword.get(opts, :preload_registration, false) do
      queryable
      |> join(:left, [payslip: p], payslip in assoc(p, :registration), as: :registration)
      |> join(:left, [registration: r], individual in assoc(r, :individual), as: :individual)
      |> join(:left, [registration: r], ra in assoc(r, :registered_at), as: :registered_at)
      |> join(:left, [individual: i], entity in assoc(i, :entity), as: :entity)
      |> preload([registration: r, registered_at: ra, individual: i, entity: e],
        registration: {r, registered_at: ra, individual: {i, entity: e}}
      )
      |> order_by([registered_at: ra], ra.trade_name)
      |> order_by([individual: i], i.name)
    else
      queryable
    end
  end
end
