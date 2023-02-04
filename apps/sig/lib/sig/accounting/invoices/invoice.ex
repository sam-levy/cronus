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
    :number,
    :issue_date,
    :amount,
    :invoiced_by,
    :invoiced_to
  ]

  def create_non_nfe_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields ++ [:delivery_date])
    |> validate_required(@required_fields)
    |> put_change(:type, :goods_and_services)
    |> base_validations()
  end

  def create_nfe_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields ++ [:delivery_date, :nfe_access_key])
    |> validate_required(@required_fields)
    |> put_change(:type, :goods_and_services)
    |> validate_numericality(:nfe_access_key)
    |> validate_length(:nfe_access_key, max: 44)
    |> base_validations()
  end

  def create_tax_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> put_change(:type, :tax)
    |> base_validations()
  end

  def base_validations(changeset) do
    changeset
    |> validate_required([:type])
    |> validate_numericality(:number)
    |> validate_length(:number, max: 9)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> unique_constraint([:number, :invoiced_by_id])
  end
end
