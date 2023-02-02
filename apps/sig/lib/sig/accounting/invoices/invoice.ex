defmodule Sig.Accounting.Invoices.Invoice do
  use Sig.Schema

  alias Sig.Entities.Entity
  alias Sig.Organizations.Org

  defenum(InvoiceType, :invoice_type, [:goods_and_services, :tax])

  schema "invoices" do
    belongs_to :org, Org, primary_key: true

    field :type, InvoiceType
    field :nfe_access_key, :string
    field :number, :string
    field :issue_date, :date
    field :delivery_date, :date
    field :amount, Money.Ecto.Amount.Type

    belongs_to :invoiced_by, Entity
    belongs_to :invoiced_to, Entity

    timestamps()
  end

  @required_fields [
    :org_id,
    :type,
    :issue_date,
    :amount,
    :invoiced_by,
    :invoiced_to
  ]

  def create_non_nfe_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields ++ [:number, :delivery_date])
    |> validate_required(@required_fields)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> unique_constraint([:number, :invoiced_by_id])
  end
end
