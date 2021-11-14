defmodule Sig.HR.Payslips.Items.Item do
  use Sig.Schema

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org

  defenum(Type, :payslip_item_type, [:payslip_item, :outside_item])

  schema "payslip_items" do
    belongs_to :org, Org, primary_key: true

    field :type, Type
    field :code, :string
    field :reference, :string
    field :description, :string
    field :entry_type, Sig.EntryType
    field :amount, Money.Ecto.Amount.Type
    field :is_payment_advance, :boolean, default: false

    belongs_to :payslip, Payslip
    belongs_to :category, Category

    timestamps()
  end

  @create_base_required_fields [
    :org_id,
    :description,
    :entry_type,
    :amount,
    :is_payment_advance,
    :payslip_id
  ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_base_required_fields ++ [:code, :reference, :category_id])
    |> validate_required(@create_base_required_fields ++ [:code, :category_id])
    |> put_change(:type, :payslip_item)
    |> validate_length(:description, max: 255)
    |> validate_length(:reference, max: 255)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> assoc_constraint(:category, name: :payslip_items_category)
    |> unique_constraint([:category_id, :payslip_id, :org_id],
      name: :payslip_items_category_unique
    )
  end

  def create_outside_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_base_required_fields)
    |> validate_required(@create_base_required_fields)
    |> put_change(:type, :outside_item)
    |> validate_length(:description, max: 255)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> validate_is_payment_advance()
  end

  def update_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> validate_money(:amount, [:gt, :eq], 0)
  end
end
