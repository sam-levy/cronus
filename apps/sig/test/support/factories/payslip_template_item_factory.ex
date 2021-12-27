defmodule Sig.Factories.PayslipTemplateItemFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

      def factory({:payslip_template_item, :payslip_item}, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        payslip_template =
          Keyword.get(attrs, :payslip_template) || insert(:payslip_template, org: org)

        payslip_category =
          Keyword.get(attrs, :payslip_category) || insert(:payslip_category, org: org)

        %PayslipTemplateItem{
          org: org,
          payslip_template: payslip_template,
          payslip_category: payslip_category,
          amount: Enum.random(100_00..2_000_00),
          type: :payslip_item
        }
      end

      def factory({:payslip_template_item, :payslip_item_model}, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        payslip_template =
          Keyword.get(attrs, :payslip_template) || insert(:payslip_template, org: org)

        payslip_recurring_item_model =
          Keyword.get(attrs, :payslip_recurring_item_model) ||
            insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

        %PayslipTemplateItem{
          org: org,
          payslip_template: payslip_template,
          payslip_recurring_item_model: payslip_recurring_item_model,
          type: :payslip_item_model
        }
      end
    end
  end
end
