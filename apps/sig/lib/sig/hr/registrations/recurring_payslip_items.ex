defmodule Sig.HR.Registrations.RecurringPayslipItems do
  import Ecto.Query

  alias Ecto.Multi

  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.HR.Registrations.RecurringPayslipItems.ListByRegistration
  alias Sig.Repo

  defdelegate list_by_registration(registration, opts \\ []), to: ListByRegistration, as: :call

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

  def create(%Registration{} = registration, %{} = attrs, type) when is_atom(type) do
    changeset =
      attrs
      |> Map.put(:org_id, registration.org_id)
      |> Map.put(:registration_id, registration.id)
      |> create_change(type)

    Multi.new()
    |> Multi.insert(:item, changeset)
    |> Multi.run(:validate_positive_amount_sum, fn _, %{item: item} ->
      items = list_by_registration(registration)

      validate_positive_amount_sum(:create, items, item.id)
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

  def subscribe_to_registration_recurring_payslip_items(%Registration{} = registration) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(registration))
  end

  def broadcast_registration_recurring_payslip_items(%Registration{} = registration) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
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
