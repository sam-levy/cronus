defmodule Sig.Finance.HistoricalAmount do
  use Sig.Schema

  alias Sig.Finance.HistoricalAmount.Add

  @primary_key false
  embedded_schema do
    field :date, :date, primary_key: true
    field :amount, Money.Ecto.Amount.Type
  end

  defdelegate add(changeset, amount_field, date_field, history_field), to: Add, as: :call

  def changeset(target \\ %__MODULE__{}, attrs) do
    target
    |> cast(attrs, [:date, :amount])
    |> validate_required([:date, :amount])
  end
end
