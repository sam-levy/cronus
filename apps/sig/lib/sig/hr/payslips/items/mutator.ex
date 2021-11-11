defmodule Sig.HR.Payslips.Items.Mutator do
  alias Ecto.Multi

  alias Sig.HR.Payslips.Categories
  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  @closed_payslip_message "cannot modify a closed payslip"

  defmodule Context do
    defstruct status: :ok,
              type: nil,
              entry_type: nil,
              attrs: nil,
              changeset: nil,
              payslip: nil,
              item: nil,
              return: nil
  end

  def create_payslip_item(%Payslip{} = payslip, %{} = attrs) do
    %Context{type: :payslip_item, attrs: attrs, payslip: payslip}
    |> validate_payslip()
    |> set_attrs_primary_keys()
    |> build_payslip_item_changeset()
    |> set_entry_type()
    |> create_multi()
    |> handle_return()
  end

  def create_outside_item(%Payslip{} = payslip, %{} = attrs) do
    %Context{type: :outside_item, attrs: attrs, payslip: payslip}
    |> validate_payslip()
    |> set_attrs_primary_keys()
    |> build_outside_item_changeset()
    |> set_entry_type()
    |> create_multi()
    |> handle_return()
  end

  def update_amount(%Payslip{} = payslip, %Item{} = item, %{} = attrs) do
    %Context{attrs: attrs, item: item, payslip: payslip}
    |> validate_payslip()
    |> build_update_amount_changeset()
    |> set_entry_type()
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
    |> Item.create_changeset()
    |> handle_changeset(context)
  end

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

  defp set_entry_type(%{status: :halt} = context), do: context

  defp set_entry_type(%{item: %{entry_type: nil}} = context) do
    %{payslip: payslip, item: item} = context
    item = Items.get(payslip, item.id)

    %{context | entry_type: item.entry_type, item: item}
  end

  defp set_entry_type(%{item: %{entry_type: entry_type}} = context) do
    %{context | entry_type: entry_type}
  end

  defp set_entry_type(%{type: :payslip_item} = context) do
    %{payslip: %{org_id: org_id}, attrs: %{category_id: category_id}} = context
    category = Categories.get(org_id, category_id)

    %{context | entry_type: category.entry_type}
  end

  defp set_entry_type(%{type: :outside_item} = context) do
    %{context | entry_type: context.changeset.changes.outside_item_entry_type}
  end

  defp create_multi(%{status: :halt} = context), do: context

  defp create_multi(context) do
    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(context.payslip) end)
    |> Multi.insert(:item, context.changeset)
    |> Multi.run(:update_payslip_amount, &handle_payslip_amount_update/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp update_multi(%{status: :halt} = context), do: context

  defp update_multi(context) do
    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(context.payslip) end)
    |> Multi.update(:item, context.changeset)
    |> Multi.run(:update_payslip_amount, &handle_payslip_amount_update/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp delete_multi(%{status: :halt} = context), do: context

  defp delete_multi(context) do
    Multi.new()
    |> Multi.run(:ensure_payslip_is_open, fn _, _ -> ensure_payslip_is_open(context.payslip) end)
    |> Multi.delete(:item, context.item)
    |> Multi.run(:update_payslip_amount, &handle_payslip_amount_update/2)
    |> Repo.transaction()
    |> handle_multi_return(context)
  end

  defp ensure_payslip_is_open(%Payslip{id: id, org_id: org_id}) do
    case Payslips.get_by(id: id, org_id: org_id) do
      %{is_closed: false} = payslip -> {:ok, payslip}
      _payslip -> {:error, @closed_payslip_message}
    end
  end

  defp handle_payslip_amount_update(_repo, %{ensure_payslip_is_open: payslip}) do
    payslip
    |> Items.list_by_payslip()
    |> calculate_amount()
    |> case do
      %Money{amount: amount} when amount < 0 ->
        {:error, "payslip amount cannot be negative"}

      %Money{amount: amount} when amount == payslip.amount.amount ->
        {:ok, payslip}

      %Money{amount: amount} ->
        payslip
        |> Payslip.update_amount_changeset(%{amount: amount})
        |> Repo.update()
    end
  end

  defp calculate_amount(items) do
    Money.subtract(Items.sum_by(:credit, items), Items.sum_by(:debit, items))
  end

  defp handle_multi_return({:ok, %{item: item}}, context), do: %{context | return: item}
  defp handle_multi_return({:error, _, reason, _}, context), do: put_error(context, reason)

  defp put_error(context, error), do: %{context | status: :halt, return: error}

  defp handle_return(%{status: :ok, return: item}), do: {:ok, item}
  defp handle_return(%{status: :halt, return: error}), do: {:error, error}
end
