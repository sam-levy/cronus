defmodule Sig.HR.Payslips.CreateFromModel do
  alias Ecto.Multi

  alias Sig.Finance
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Registrations.Registration
  alias Sig.HR.Registrations.RecurringPayslipItems
  alias Sig.Repo

  def call(%Registration{} = registration, %{} = attrs, opts \\ []) do
    insert_all_opts = Sig.Changeset.add_timestamps_placeholders_opts(returning: true)

    Multi.new()
    |> Multi.run(:payslip, fn _, _ -> Payslips.create(registration, attrs) end)
    |> Multi.run(:payslip_items_attrs, fn _, %{payslip: payslip} ->
      build_payslip_items_attrs(registration, payslip)
    end)
    |> Multi.insert_all(:payslip_items, Item, & &1.payslip_items_attrs, insert_all_opts)
    |> Multi.run(
      :update_payslip_amount,
      fn _, %{payslip: payslip, payslip_items: {_, items}} ->
        Payslips.update_payslip_amount(payslip, items)
      end
    )
    |> Multi.run(:payables, &create_payables(&1, &2, registration, opts))
    |> Repo.transaction()
    |> case do
      {:error, _operation, reason, _changes} -> {:error, reason}
      {:ok, %{payslip: payslip}} -> {:ok, payslip}
    end
  end

  defp build_payslip_items_attrs(registration, payslip) do
    start_date = Date.beginning_of_month(payslip.start_date)

    registration
    |> RecurringPayslipItems.list_by_registration(start_date: start_date)
    |> Enum.reduce_while(%{codes: MapSet.new(), attrs: []}, &validate_attrs(&1, &2, payslip))
    |> case do
      %{attrs: attrs} -> {:ok, attrs}
      {:error, error} -> {:error, error}
    end
  end

  defp validate_attrs(rpi, acc, payslip) do
    with {:duplicated_rpi, false} <- {:duplicated_rpi, duplicated_rpi?(acc, rpi)},
         %{valid?: true} = changeset <- Items.build_changeset_from(rpi, payslip) do
      attrs =
        changeset.changes
        |> Map.drop([:category_id])
        |> Sig.Changeset.add_timestamps_placeholders()

      {:cont, handle_acc(acc, attrs)}
    else
      {:duplicated_rpi, true} -> {:halt, {:error, "Existem itens duplicados no holerite modelo"}}
      %{valid?: false} = changeset -> {:halt, {:error, changeset}}
    end
  end

  defp duplicated_rpi?(_acc, %{type: :outside_item}), do: false
  defp duplicated_rpi?(acc, %{code: code}), do: MapSet.member?(acc.codes, code)

  defp handle_acc(acc, %{type: :outside_item} = attrs) do
    Sig.Map.flat_put(acc, :attrs, attrs)
  end

  defp handle_acc(acc, %{type: :payslip_item, code: code} = attrs) do
    codes = MapSet.put(acc.codes, code)

    acc
    |> Sig.Map.flat_put(:attrs, attrs)
    |> Map.put(:codes, codes)
  end

  defp create_payables(_repo, %{payslip: payslip, payslip_items: {_, items}}, registration, opts) do
    Finance.create_payables_for_payslip(registration, payslip, items, opts)
  end
end
