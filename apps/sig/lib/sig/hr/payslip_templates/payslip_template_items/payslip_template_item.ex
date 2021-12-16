defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem do
  use Sig.Schema

  alias Sig.HR.Payslips.Categories.Category
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.Organizations.Org

  defenum(Type, :payslip_template_item_type, [:payslip_item, :payslip_item_model])

  schema "payslip_template_items" do
    belongs_to :org, Org, primary_key: true

    field :type, Type
    field :amount, Money.Ecto.Amount.Type

    belongs_to :payslip_category, Category
    belongs_to :payslip_recurring_item_model, RecurringItemModel
    belongs_to :payslip_template, PayslipTemplate

    field :category_code, :string, virtual: true

    timestamps()
  end

  @base_fields [:org_id, :payslip_template_id]
  @payslip_item_fields @base_fields ++ [:amount, :payslip_category_id]
  @payslip_item_model_fields @base_fields ++ [:payslip_recurring_item_model_id]

  def create_payslip_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @payslip_item_fields)
    |> validate_required(@payslip_item_fields)
    |> put_change(:type, :payslip_item)
    |> validate_money(:amount, [:gt, :eq], 0)
    |> assoc_constraint(:payslip_category)
    |> unique_constraint(:payslip_category, name: :payslip_template_items_category_unique)
  end

  def create_payslip_model_item_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @payslip_item_model_fields)
    |> validate_required(@payslip_item_model_fields)
    |> put_change(:type, :payslip_item_model)
    |> assoc_constraint(:payslip_recurring_item_model)
    |> unique_constraint(:payslip_recurring_item_model_id,
      name: :payslip_template_items_model_unique
    )
  end
end
