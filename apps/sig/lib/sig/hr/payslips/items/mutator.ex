defmodule Sig.HR.Payslips.Items.Mutator do
  alias Ecto.Multi

  alias Sig.Finance.Payables.PayablesForPayslip
  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @closed_payslip_message "can't modify a closed payslip"

  def create_payslip_item(%Payslip{} = payslip, %{} = attrs) do
    %{type: :payslip_item, item: nil, attrs: attrs, payslip: payslip}
    |> Extep.new()
    |> Extep.run(&validate_payslip/1)
    |> Extep.run(&set_attrs_primary_keys/1, :attrs)
    |> Extep.run(&build_payslip_item_changeset/1, :changeset)
    |> Extep.run(&create_multi/1, :item)
    |> Extep.return(:item)
  end

  def create_outside_item(%Payslip{} = payslip, %{} = attrs) do
    %{type: :outside_item, item: nil, attrs: attrs, payslip: payslip}
    |> Extep.new()
    |> Extep.run(&validate_payslip/1)
    |> Extep.run(&set_attrs_primary_keys/1, :attrs)
    |> Extep.run(&build_outside_item_changeset/1, :changeset)
    |> Extep.run(&create_multi/1, :item)
    |> Extep.return(:item)
  end

  def update_amount(%Payslip{} = payslip, %Item{} = item, %{} = attrs) do
    %{item: item, attrs: attrs, payslip: payslip}
    |> Extep.new()
    |> Extep.run(&validate_payslip/1)
    |> Extep.run(&build_update_amount_changeset/1, :changeset)
    |> Extep.run(&update_multi/1, :updated_item)
    |> Extep.return(:updated_item)
  end

  def delete_item(%Payslip{} = payslip, %Item{} = item) do
    %{item: item, payslip: payslip}
    |> Extep.new()
    |> Extep.run(&validate_payslip/1)
    |> Extep.run(&delete_multi/1, :deleted_item)
    |> Extep.return(:deleted_item)
  end

  defp validate_payslip(%{payslip: %{is_closed: true}}), do: {:error, @closed_payslip_message}
  defp validate_payslip(%{item: %{payslip_id: id}, payslip: %{id: id}}), do: :ok
  defp validate_payslip(%{item: nil}), do: :ok
  defp validate_payslip(_context), do: {:error, "item doesn't belong to payslip"}

  defp set_attrs_primary_keys(%{attrs: attrs, payslip: payslip}) do
    attrs =
      attrs
      |> Map.put(:org_id, payslip.org_id)
      |> Map.put(:payslip_id, payslip.id)

    {:ok, attrs}
  end

  defp build_payslip_item_changeset(%{attrs: attrs}) do
    attrs
    |> fill_category_fields()
    |> Item.create_changeset()
    |> handle_changeset()
  end

  defp fill_category_fields(%{category_id: category_id} = attrs) when not is_nil(category_id) do
    case Categories.fetch(attrs.org_id, category_id) do
      {:ok, category} ->
        attrs
        |> Map.put(:code, category.code)
        |> Map.put(:entry_type, category.entry_type)
        |> Map.put(:description, category.description)
        |> Map.put(:is_payment_advance, category.is_payment_advance)

      {:error, :not_found} ->
        attrs
    end
  end

  defp fill_category_fields(attrs), do: attrs

  defp build_outside_item_changeset(%{attrs: attrs}) do
    attrs
    |> Item.create_outside_item_changeset()
    |> handle_changeset()
  end

  defp build_update_amount_changeset(%{item: item, attrs: attrs}) do
    item
    |> Item.update_amount_changeset(attrs)
    |> handle_changeset()
  end

  defp handle_changeset(%{valid?: true} = changeset), do: {:ok, changeset}
  defp handle_changeset(changeset), do: {:error, changeset}

  defp create_multi(context) do
    %{payslip: payslip, changeset: changeset} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.insert(:item, changeset)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi()
  end

  defp update_multi(context) do
    %{payslip: payslip, changeset: changeset} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.update(:item, changeset)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi()
  end

  defp delete_multi(context) do
    %{payslip: payslip, item: item} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.delete(:item, item)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi()
  end

  defp ensure_payslip_is_open(%Payslip{id: id, org_id: org_id}) do
    case Payslips.get_by(id: id, org_id: org_id) do
      %{is_closed: false} = payslip -> {:ok, payslip}
      _payslip -> {:error, @closed_payslip_message}
    end
  end

  defp update_payslip_amount(_repo, %{ensure_payslip_is_open: payslip}) do
    items = Items.list_by_payslip(payslip)

    Payslips.update_payslip_amount(payslip, items)
  end

  defp update_auto_adjustable_amount_payable(_repo, %{update_payslip_amount: payslip}) do
    PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
  end

  defp handle_multi({:ok, %{item: item}}), do: {:ok, item}
  defp handle_multi({:error, _, reason, _}), do: {:error, reason}
end
