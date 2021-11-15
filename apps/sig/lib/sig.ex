defmodule Sig do
  @moduledoc """
  Sig keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  def sum_by(entry_type, []) when entry_type in [:credit, :debit], do: Money.new(0)

  def sum_by(entry_type, [item | _] = items) when entry_type in [:credit, :debit] and is_struct(item) do
    Enum.reduce(items, Money.new(0), fn
      %{entry_type: ^entry_type, amount: amount}, acc -> Money.add(amount, acc)
      _item, acc -> acc
    end)
  end
end
