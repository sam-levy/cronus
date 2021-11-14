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

  def create_change(%{} = attrs \\ %{}) do
    Item.create_changeset(attrs)
  end

  def create_outside_item_change(%{} = attrs \\ %{}) do
    Item.create_outside_item_changeset(attrs)
  end

  def update_amount_change(%Item{} = item, %{} = attrs \\ %{}) do
    Item.update_amount_changeset(item, attrs)
  end

  def list_by_payslip(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> Repo.all()
    |> Enum.sort_by(&handle_sort/1)
  end

  defp handle_sort(%Item{code: nil}), do: "ZZZ"
  defp handle_sort(%Item{code: code}), do: code

  def sum_payments_in_advance_items_by_payslip(%Payslip{} = payslip) do
    payslip
    |> query_by_payslip()
    |> where(entry_type: :debit)
    |> where(is_payment_advance: true)
    |> Repo.aggregate(:sum, :amount)
    |> case do
      %Money{} = sum -> sum
      nil -> Money.new(0)
    end
  end

  def get(%Payslip{} = payslip, id) when is_binary(id) do
    payslip
    |> query_by_payslip()
    |> where(id: ^id)
    |> Repo.one()
  end

  def fetch(%Payslip{} = payslip, id) when is_binary(id) do
    case get(payslip, id) do
      %Item{} = item -> {:ok, item}
      nil -> {:error, :not_found}
    end
  end

  def sum_by(entry_type, []) when entry_type in [:credit, :debit], do: Money.new(0)

  def sum_by(entry_type, [%Item{} | _] = items) when entry_type in [:credit, :debit] do
    Enum.reduce(items, Money.new(0), fn
      %{entry_type: ^entry_type, amount: amount}, acc -> Money.add(amount, acc)
      _item, acc -> acc
    end)
  end

  def subscribe_to_payslip_items(%Payslip{} = payslip) do
    Phoenix.PubSub.subscribe(Sig.PubSub, topic(payslip))
  end

  def unsubscribe_from_payslip_items(%Payslip{} = payslip) do
    Phoenix.PubSub.unsubscribe(Sig.PubSub, topic(payslip))
  end

  def broadcast_payslip_items(%Payslip{} = payslip) do
    Phoenix.PubSub.broadcast(
      Sig.PubSub,
      topic(payslip),
      {:updated_payslip_items, list_by_payslip(payslip)}
    )
  end

  defp topic(%Payslip{} = payslip), do: "payslip_id:" <> payslip.id <> ":items"

  defp query_by_payslip(payslip) do
    Item
    |> where(org_id: ^payslip.org_id)
    |> where(payslip_id: ^payslip.id)
  end
end
