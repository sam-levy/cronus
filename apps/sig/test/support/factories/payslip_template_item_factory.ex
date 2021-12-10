defmodule Sig.Factories.PayslipTemplateItemFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

      def factory(:payslip_template_item, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        payslip_template =
          Keyword.get(attrs, :payslip_template) || insert(:payslip_template, org: org)

        payslip_recurring_item_model =
          Keyword.get(attrs, :payslip_recurring_item_model) ||
            insert({:payslip_recurring_item_model, :fixed_amount}, org: org)

        %PayslipTemplateItem{
          org: org,
          payslip_template: payslip_template,
          payslip_recurring_item_model: payslip_recurring_item_model
        }
      end
    end
  end
end
