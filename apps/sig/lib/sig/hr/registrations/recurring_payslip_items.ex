defmodule Sig.HR.Registrations.RecurringPayslipItems do
  import Ecto.Query
  import Sig.Broadcaster

  alias Ecto.Multi

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems.CreateFromPayslipTemplate
  alias Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.Repo

  defdelegate list_by_registration(registration, opts \\ []), to: ListByRegistration, as: :call

  defdelegate create_from_payslip_template(registration, template_id),
    to: CreateFromPayslipTemplate,
    as: :call

  def create_change(attrs \\ %{}, type)

  def create_change(%{} = attrs, :payslip_item) do
    RecurringPayslipItem.create_payslip_item_changeset(attrs)
  end

  def create_change(%{} = attrs, :payslip_item_model) do
    RecurringPayslipItem.create_payslip_item_model_changeset(attrs)
  end

  def create_change(%{} = attrs, :outside_item) do
    RecurringPayslipItem.create_outside_item_changeset(attrs)
  end

  def list_by(schema, _opts \\ []) do
    schema
    |> query_by()
    |> Repo.all()
  end

  def count_by(schema) do
    schema
    |> query_by()
    |> Repo.aggregate(:count)
  end

  def create(%Registration{} = registration, %{} = attrs, type) when is_atom(type) do
    changeset =
      attrs
      |> Map.put(:org_id, registration.org_id)
      |> Map.put(:registration_id, registration.id)
      |> create_change(type)

    Multi.new()
    |> Multi.insert(:item, changeset)
    |> Multi.run(:items, fn _, _ -> {:ok, list_by_registration(registration)} end)
    |> Multi.run(:validate_positive_amount_sum, fn _, %{item: item, items: items} ->
      validate_positive_amount_sum(:create, items, item.id)
    end)
    |> Multi.run(:validate_unique_description, fn _, %{items: items} ->
      validate_unique_description(items)
    end)
    |> Repo.transaction()
    |> handle_return()
  end

  def delete(%Registration{} = registration, id) when is_binary(id) do
    item_queryable =
      RecurringPayslipItem
      |> where(id: ^id)
      |> where(org_id: ^registration.org_id)
      |> where(registration_id: ^registration.id)
      |> select([item], item)

    items = list_by_registration(registration)

    Multi.new()
    |> Multi.delete_all(:item, item_queryable)
    |> Multi.run(:validate_positive_amount_sum, fn
      _, %{item: {1, [item]}} -> validate_positive_amount_sum(:delete, items, item.id)
      _, _ -> {:ok, nil}
    end)
    |> Repo.transaction()
    |> handle_return()
  end

  defp validate_unique_description(items) do
    items_count = Enum.count(items)
    uniques_count = items |> Enum.uniq_by(& &1.description) |> Enum.count()

    if items_count == uniques_count do
      {:ok, nil}
    else
      {:error, "has already been taken"}
    end
  end

  # TODO: Add tests
  def validate_positive_amount_sum(
        :delete,
        [%RecurringPayslipItem{} | _] = items,
        deleted_item_id
      )
      when is_binary(deleted_item_id) do
    case Enum.find(items, &(&1.id == deleted_item_id)) do
      %RecurringPayslipItem{entry_type: :debit} ->
        {:ok, nil}

      %RecurringPayslipItem{entry_type: :credit} = item ->
        items
        |> List.delete(item)
        |> do_validate_positive_amount_sum()

      nil ->
        do_validate_positive_amount_sum(items)
    end
  end

  def validate_positive_amount_sum(
        :create,
        [%RecurringPayslipItem{} | _] = items,
        created_item_id
      )
      when is_binary(created_item_id) do
    Enum.find(items, &(&1.id == created_item_id))

    case Enum.find(items, &(&1.id == created_item_id)) do
      %RecurringPayslipItem{entry_type: :credit} -> {:ok, nil}
      _ -> do_validate_positive_amount_sum(items)
    end
  end

  defp do_validate_positive_amount_sum(items) do
    amount_sum = Money.subtract(Sig.sum_by(:credit, items), Sig.sum_by(:debit, items))

    if Money.negative?(amount_sum) do
      {:error, "Recurring payslip items amount sum can't be negative"}
    else
      {:ok, nil}
    end
  end

  defp query_by(%Registration{} = registration) do
    RecurringPayslipItem
    |> where(org_id: ^registration.org_id)
    |> where(registration_id: ^registration.id)
  end

  defp query_by(%RecurringItemModel{} = rim) do
    RecurringPayslipItem
    |> where(org_id: ^rim.org_id)
    |> where(payslip_recurring_item_model_id: ^rim.id)
  end

  defp query_by(%Category{} = category) do
    RecurringPayslipItem
    |> where(org_id: ^category.org_id)
    |> where(payslip_category_id: ^category.id)
  end

  def subscribe_to_registration_recurring_payslip_items(schema) do
    subscribe(topic(schema))
  end

  def broadcast_registration_recurring_payslip_items(%Registration{} = registration) do
    broadcast(
      topic(registration),
      {:updated_registration_recurring_payslip_items, list_by_registration(registration)}
    )
  end

  defp topic(%Registration{} = registration) do
    "registration_id:" <> registration.id <> ":recurring_payslip_items"
  end

  defp handle_return({:ok, %{item: {1, [item]}}}), do: {:ok, item}
  defp handle_return({:ok, %{item: {0, []}}}), do: {:error, :not_found}
  defp handle_return({:ok, %{item: item}}), do: {:ok, item}
  defp handle_return({:error, _operation, reason, _changes}), do: {:error, reason}
end
