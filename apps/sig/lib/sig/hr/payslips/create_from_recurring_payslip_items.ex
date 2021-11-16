defmodule Sig.HR.Payslips.CreateFromRecurringPayslipItems do
  import Ecto.Changeset, only: [apply_action: 2]

  alias Ecto.Multi

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem
  alias Sig.Repo

  def call(%Registration{} = registration, %{} = attrs) do
    Multi.new()
    |> Multi.run(:payslip, fn _, _ -> Payslips.create(registration, attrs) end)
    |> Multi.run(:payslip_items_params, fn _, %{payslip: payslip} ->
      build_payslip_items_params(registration, payslip)
    end)
    |> Multi.insert_all(:payslip_items, Item, & &1.payslip_items_params, returning: true)
    |> Multi.run(
      :update_payslip_amount,
      fn _, %{payslip: payslip, payslip_items: {_, items}} ->
        Payslips.update_payslip_amount(payslip, items)
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{payslip: payslip}} -> {:ok, payslip}
    end
  end

  defp build_payslip_items_params(registration, payslip) do
    start_date = Date.beginning_of_month(payslip.start_date)

    registration
    |> RecurringPayslipItems.list_by_registration(start_date: start_date)
    |> Enum.reduce_while([], &handle_params(&1, &2, payslip.id))
    |> case do
      params when is_list(params) -> {:ok, params}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp handle_params(rpi, acc, payslip_id) do
    with %{valid?: true} = changeset <- build_changeset(rpi, payslip_id),
         {:ok, _item} <- apply_action(changeset, :insert) do
      params = add_timestamps(changeset.changes)

      {:cont, [params | acc]}
    else
      %{valid?: false} = changeset -> {:halt, {:error, changeset}}
      {:error, changeset} -> {:halt, {:error, changeset}}
    end
  end

  defp build_changeset(%RecurringPayslipItem{type: :outside_item} = rpi, payslip_id) do
    Item.create_outside_item_changeset(%{
      org_id: rpi.org_id,
      description: rpi.description,
      entry_type: rpi.entry_type,
      is_payment_advance: rpi.is_payment_advance,
      amount: rpi.amount,
      payslip_id: payslip_id
    })
  end

  defp build_changeset(%RecurringPayslipItem{type: :payslip_item} = rpi, payslip_id) do
    rpi
    |> handle_payslip_item_attrs(payslip_id)
    |> Map.put(:category_id, rpi.payslip_category_id)
    |> Item.create_changeset()
  end

  defp build_changeset(%RecurringPayslipItem{type: :payslip_item_model} = rpi, payslip_id) do
    rpi
    |> handle_payslip_item_attrs(payslip_id)
    |> Map.put(:category_id, rpi.payslip_recurring_item_model.category_id)
    |> Item.create_changeset()
  end

  defp handle_payslip_item_attrs(rpi, payslip_id) do
    %{
      org_id: rpi.org_id,
      description: rpi.description,
      entry_type: rpi.entry_type,
      is_payment_advance: rpi.is_payment_advance,
      amount: rpi.amount,
      payslip_id: payslip_id,
      code: rpi.code
    }
  end

  defp add_timestamps(attrs) do
    attrs
    |> Map.put(:inserted_at, DateTime.utc_now())
    |> Map.put(:updated_at, DateTime.utc_now())
  end
end
