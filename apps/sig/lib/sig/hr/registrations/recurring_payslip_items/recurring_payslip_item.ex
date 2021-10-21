defmodule Sig.HR.Registrations.RecurringPayslipItems.RecurringPayslipItem do
  use Sig.Schema

  alias Sig.Organizations.Org
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Registrations.Registration

  defenum(Type, :employee_registration_recurring_payslip_item_type, [
    :payslip_item,
    :payslip_item_model,
    :outside_item
  ])

  schema "employee_registration_recurring_payslip_items" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :type, Type
    field :outside_item_description, :string
    field :outside_item_entry_type, Sig.EntryType
    field :item_amount, Money.Ecto.Amount.Type

    belongs_to :payslip_category, Category
    belongs_to :payslip_recurring_item_model, RecurringItemModel

    field :code, :string, virtual: true
    field :description, :string, virtual: true
    field :entry_type, Sig.EntryType, virtual: true
    field :amount, Money.Ecto.Amount.Type, virtual: true

    timestamps()
  end

  @create_base_required_fields [:org_id, :registration_id]

  @create_payslip_item_fields @create_base_required_fields ++ [:item_amount, :payslip_category_id]

  def create_payslip_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_payslip_item_fields)
    |> validate_required(@create_payslip_item_fields)
    |> put_change(:type, :payslip_item)
    |> validate_money(:item_amount, [:gt, :eq], 0)
    |> assoc_constraint(:payslip_category,
      name: :employee_registration_recurring_payslip_items_category
    )
  end

  @create_payslip_item_model_fields @create_base_required_fields ++
                                      [:payslip_recurring_item_model_id]

  def create_payslip_item_model_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_payslip_item_model_fields)
    |> validate_required(@create_payslip_item_model_fields)
    |> put_change(:type, :payslip_item_model)
    |> assoc_constraint(:payslip_recurring_item_model,
      name: :employee_registration_recurring_payslip_items_item_model
    )
  end

  @create_outside_item_fields @create_base_required_fields ++
                                [
                                  :item_amount,
                                  :outside_item_description,
                                  :outside_item_entry_type
                                ]

  def create_outside_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_outside_item_fields)
    |> validate_required(@create_outside_item_fields)
    |> put_change(:type, :outside_item)
    |> validate_length(:outside_item_description, max: 255)
    |> validate_money(:item_amount, [:gt, :eq], 0)
    |> unique_constraint([:outside_item_description, :registration_id, :org_id],
      name: :employee_registration_recurring_payslip_items_description
    )
  end
end
