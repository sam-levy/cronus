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
    |> Multi.run(:payables, &create_payables(&1, &2, registration, opts))
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
    |> Enum.reduce_while([], &handle_params(&1, &2, payslip))
    |> case do
      params when is_list(params) -> {:ok, params}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp handle_params(rpi, acc, payslip) do
    with %{valid?: true} = changeset <- Items.build_changeset_from(rpi, payslip),
         {:ok, _item} <- Ecto.Changeset.apply_action(changeset, :insert) do
      params =
        changeset.changes
        |> Map.drop([:category_id])
        |> Sig.Changeset.add_timestamps()

      {:cont, [params | acc]}
    else
      %{valid?: false} = changeset -> {:halt, {:error, changeset}}
      {:error, changeset} -> {:halt, {:error, changeset}}
    end
  end

  defp create_payables(_repo, %{payslip: payslip, payslip_items: {_, items}}, registration, opts) do
    Finance.create_payables_for_payslip(registration, payslip, items, opts)
  end
end
