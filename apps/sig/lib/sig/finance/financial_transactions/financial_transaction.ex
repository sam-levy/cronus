defmodule Sig.Finance.FinancialTransactions.FinancialTransaction do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "financial_transactions" do
    belongs_to :org, Org, primary_key: true

    field :type, Sig.Enums.FinancialTransaction.Type
    field :placement_date, :date
    field :clearing_date, :date
    field :amount, Money.Ecto.Amount.Type
    field :entry_type, Sig.EntryType
    field :description, :string

    belongs_to :transfer_counterparty, __MODULE__

    timestamps()
  end

  @create_required_fields [:org_id, :type, :placement_date, :amount, :entry_type, :description]
  @create_optional_fields [:clearing_date, :transfer_counterparty_id]

  @create_fields @create_required_fields ++ @create_optional_fields

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_money(:amount, :gt, 0)
    |> validate_length(:description, max: 255)
    |> validate_dates(:clearing_date, [:gt, :eq], :placement_date)
    |> assoc_constraint(:transfer_counterparty)
  end
end
