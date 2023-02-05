defmodule Sig.Factories.InvoiceFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Accounting.Invoices.Invoice
      alias Sig.Accounting.Invoices.Invoice.InvoiceType

      def factory(:non_nfe_invoice, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %Invoice{
          org: org,
          type: :goods_and_services,
          number: random_string_number(9),
          issue_date: random_past_date(30),
          delivery_date: random_past_date(30),
          invoiced_by: Keyword.get(attrs, :invoiced_by) || insert(:entity, org: org),
          invoiced_to: Keyword.get(attrs, :invoiced_to) || insert(:entity, org: org),
          amount: Enum.random(100_00..5_000_00) |> Money.new()
        }
      end

      def factory(:nfe_invoice, attrs) do
        invoice = build(:non_nfe_invoice, attrs)

        %Invoice{invoice | nfe_access_key: random_string_number(44)}
      end

      def factory(:tax_invoice, attrs) do
        invoice = build(:non_nfe_invoice, attrs)

        %Invoice{invoice | type: :tax, delivery_date: nil}
      end

      def random_enum_value(:invoice_type) do
        random_enum_value(InvoiceType)
      end
    end
  end
end
