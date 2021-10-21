defmodule Sig.HR.Payslips.Items.Item do
  use Sig.Schema

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org

  defenum(Type, :payslip_item_type, [:payslip_item, :outside_item])

  schema "payslip_items" do
    belongs_to :org, Org, primary_key: true

    field :type, Type
    field :reference, :string
    field :outside_item_description, :string
    field :outside_item_entry_type, Sig.EntryType
    field :amount, Money.Ecto.Amount.Type

    belongs_to :payslip, Payslip
    belongs_to :category, Category

    field :description, :string, virtual: true
    field :entry_type, Sig.EntryType, virtual: true

    timestamps()
  end

  @create_base_required_fields [:org_id, :amount, :payslip_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_base_required_fields ++ [:reference, :category_id])
    |> validate_required(@create_base_required_fields ++ [:category_id])
    |> put_change(:type, :payslip_item)
    |> validate_length(:reference, max: 255)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> assoc_constraint(:category, name: :payslip_items_category)
  end

  @create_outside_item_fields @create_base_required_fields ++
                                [:outside_item_description, :outside_item_entry_type]

  def create_outside_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_outside_item_fields)
    |> validate_required(@create_outside_item_fields)
    |> put_change(:type, :outside_item)
    |> validate_length(:outside_item_description, max: 255)
    |> validate_money(:amount, [:gt, :eq], 0)
  end

  def update_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> validate_money(:amount, [:gt, :eq], 0)
  end
end
