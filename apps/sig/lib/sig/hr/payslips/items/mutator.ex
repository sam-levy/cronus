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

  defmodule Context do
    defstruct status: :ok,
              type: nil,
              item: nil,
              attrs: nil,
              return: nil,
              payslip: nil,
              changeset: nil,
              entry_type: nil
  end

  def create_payslip_item(%Payslip{} = payslip, %{} = attrs) do
    %Context{type: :payslip_item, attrs: attrs, payslip: payslip}
    |> validate_payslip()
    |> set_attrs_primary_keys()
    |> build_payslip_item_changeset()
    |> create_multi()
    |> handle_return()
  end

  def create_outside_item(%Payslip{} = payslip, %{} = attrs) do
    %Context{type: :outside_item, attrs: attrs, payslip: payslip}
    |> validate_payslip()
    |> set_attrs_primary_keys()
    |> build_outside_item_changeset()
    |> create_multi()
    |> handle_return()
  end

  def update_amount(%Payslip{} = payslip, %Item{} = item, %{} = attrs) do
    %Context{attrs: attrs, item: item, payslip: payslip}
    |> validate_payslip()
    |> build_update_amount_changeset()
    |> update_multi()
    |> handle_return()
  end

  def delete_item(%Payslip{} = payslip, %Item{} = item) do
    %Context{item: item, payslip: payslip}
    |> validate_payslip()
    |> delete_multi()
    |> handle_return()
  end

  defp validate_payslip(%{payslip: %{is_closed: true}} = context) do
    put_error(context, @closed_payslip_message)
  end

  defp validate_payslip(%{item: %{payslip_id: id}, payslip: %{id: id}} = context), do: context

  defp validate_payslip(%{item: nil} = context), do: context

  defp validate_payslip(context), do: put_error(context, "item doesn't belong to payslip")

  defp set_attrs_primary_keys(%{status: :halt} = context), do: context

  defp set_attrs_primary_keys(%{attrs: attrs, payslip: payslip} = context) do
    attrs =
      attrs
      |> Map.put(:org_id, payslip.org_id)
      |> Map.put(:payslip_id, payslip.id)

    %{context | attrs: attrs}
  end

  defp build_payslip_item_changeset(%{status: :halt} = context), do: context

  defp build_payslip_item_changeset(%{attrs: attrs} = context) do
    attrs
    |> fill_category_fields()
    |> Item.create_changeset()
    |> handle_changeset(context)
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

  defp build_outside_item_changeset(%{status: :halt} = context), do: context

  defp build_outside_item_changeset(%{attrs: attrs} = context) do
    attrs
    |> Item.create_outside_item_changeset()
    |> handle_changeset(context)
  end

  defp build_update_amount_changeset(%{status: :halt} = context), do: context

  defp build_update_amount_changeset(%{item: item, attrs: attrs} = context) do
    item
    |> Item.update_amount_changeset(attrs)
    |> handle_changeset(context)
  end

  defp handle_changeset(%{valid?: true} = changeset, context) do
    %{context | changeset: changeset}
  end

  defp handle_changeset(changeset, context), do: put_error(context, changeset)

  defp create_multi(%{status: :halt} = context), do: context

  defp create_multi(context) do
    %{payslip: payslip, changeset: changeset} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.insert(:item, changeset)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp update_multi(%{status: :halt} = context), do: context

  defp update_multi(context) do
    %{payslip: payslip, changeset: changeset} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.update(:item, changeset)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp delete_multi(%{status: :halt} = context), do: context

  defp delete_multi(context) do
    %{payslip: payslip, item: item} = context

    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(payslip) end)
    |> Multi.delete(:item, item)
    |> Multi.run(:update_payslip_amount, &update_payslip_amount/2)
    |> Multi.run(:update_auto_adjustable_amount_payable, &update_auto_adjustable_amount_payable/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp ensure_payslip_is_open(%Payslip{id: id, org_id: org_id}) do
    case Payslips.get_by(id: id, org_id: org_id) do
      %{is_closed: false} = payslip -> {:ok, payslip}
      _payslip -> {:error, @closed_payslip_message}
    end
  end

  defp update_payslip_amount(_repo, %{ensure_payslip_is_open: payslip}) do
    payslip
    |> Items.list_by_payslip()
    |> calculate_amount()
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

  defp calculate_amount(items) do
    Money.subtract(Sig.sum_by(:credit, items), Sig.sum_by(:debit, items))
  end

  defp update_auto_adjustable_amount_payable(_repo, %{update_payslip_amount: payslip}) do
    PayablesForPayslip.update_auto_adjustable_amount_payable(payslip)
  end

  defp handle_multi_return({:ok, %{item: item}}, context), do: %{context | return: item}
  defp handle_multi_return({:error, _, reason, _}, context), do: put_error(context, reason)

  defp put_error(context, error), do: %{context | status: :halt, return: error}

  defp handle_return(%{status: :ok, return: item}), do: {:ok, item}
  defp handle_return(%{status: :halt, return: error}), do: {:error, error}
end
