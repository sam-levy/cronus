defmodule Sig.HR.Payslips.Items do
  import Ecto.Query

  alias Sig.HR.Payslips.Items.Item
  alias Sig.HR.Payslips.Items.Mutator
  alias Sig.HR.Payslips.Payslip
  alias Sig.Repo

  defdelegate create_payslip_item(payslip, attrs), to: Mutator
  defdelegate create_outside_item(payslip, attrs), to: Mutator
  defdelegate update_amount(payslip, item, attrs), to: Mutator
  defdelegate delete_item(payslip, item), to: Mutator

  def list_by_payslip(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> preaload_category()
    |> Repo.all()
    |> fill_virtual_fields()
    |> Enum.sort_by(&handle_sort/1)
  end

  def get(%Payslip{} = payslip, id) when is_binary(id) do
    payslip
    |> query_by_payslip()
    |> where(id: ^id)
    |> preaload_category()
    |> Repo.one()
    |> fill_virtual_fields()
  end

  def sum_by(entry_type, []) when entry_type in [:credit, :debit], do: Money.new(0)

  def sum_by(entry_type, [%Item{} | _] = items) when entry_type in [:credit, :debit] do
    Enum.reduce(items, 0, fn
      %{entry_type: ^entry_type, amount: amount}, acc -> Money.add(amount, acc)
      _item, acc -> acc
    end)
  end

  defp query_by_payslip(payslip) do
    Item
    |> where(org_id: ^payslip.org_id)
    |> where(payslip_id: ^payslip.id)
  end

  defp preaload_category(queryable) do
    queryable
    |> join(:left, [item], category in assoc(item, :category), as: :category)
    |> preload([_, category: category], category: category)
  end

  defp fill_virtual_fields([]), do: []

  defp fill_virtual_fields([%Item{} | _] = items) do
    Enum.map(items, &fill_virtual_fields/1)
  end

  defp fill_virtual_fields(nil), do: nil

  defp fill_virtual_fields(%Item{type: :payslip_item, category: category} = item) do
    %{
      item
      | code: category.code,
        description: category.description,
        entry_type: category.entry_type
    }
  end

  defp fill_virtual_fields(%Item{type: :outside_item} = item) do
    %{item | description: item.outside_item_description, entry_type: item.outside_item_entry_type}
  end

  defp handle_sort(%Item{type: :payslip_item, category: category}), do: category.code
  defp handle_sort(_), do: "ZZZ"
end
