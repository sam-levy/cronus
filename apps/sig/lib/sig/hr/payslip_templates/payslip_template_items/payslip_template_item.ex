defmodule Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem do
  use Sig.Schema

  alias Sig.Organizations.Org
  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel

  @primary_key false
  schema "payslip_template_items" do
    belongs_to :org, Org, primary_key: true
    belongs_to :payslip_template, PayslipTemplate, primary_key: true
    belongs_to :payslip_recurring_item_model, RecurringItemModel, primary_key: true
  end

  @fields [:org_id, :payslip_template_id, :payslip_recurring_item_model_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:payslip_recurring_item_model)
  end
end
