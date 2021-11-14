defmodule Sig.Factories.PayslipItemFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.Items.Item

      def factory(:payslip_item, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        category =
          Keyword.get(attrs, :category) ||
            insert(:payslip_category, org: org, entry_type: :credit)

        amount = Keyword.get(attrs, :amount) || Enum.random(100_00..300_00)
        payslip = Keyword.get(attrs, :payslip) || insert(:payslip, org: org, amount: amount)

        %Item{
          org: org,
          type: :payslip_item,
          code: category.code,
          reference: random_string_number(),
          description: category.description,
          entry_type: category.entry_type,
          amount: amount,
          payslip: payslip,
          category: category,
          is_payment_advance: category.is_payment_advance
        }
      end

      def factory(:payslip_outside_item, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        amount = Keyword.get(attrs, :amount) || Enum.random(100_00..300_00)
        payslip = Keyword.get(attrs, :payslip) || insert(:payslip, org: org, amount: amount)

        %Item{
          org: org,
          type: :outside_item,
          description: Faker.Lorem.sentence(),
          entry_type: :credit,
          amount: amount,
          payslip: payslip,
          is_payment_advance: false
        }
      end
    end
  end
end
