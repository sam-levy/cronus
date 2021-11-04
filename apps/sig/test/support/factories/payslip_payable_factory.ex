defmodule Sig.Factories.PayslipPayableFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable

      def factory(:payslip_payable, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)

        %PayslipPayable{
          org: org,
          payslip: insert(:payslip, org: org, amount: 0),
          payable: insert(:payable_cash, org: org, amount: 0),
          is_auto_adjustable_amount: false
        }
      end
    end
  end
end
