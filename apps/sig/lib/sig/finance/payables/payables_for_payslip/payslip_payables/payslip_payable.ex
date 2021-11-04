defmodule Sig.Finance.Payables.PayablesForPayslip.PayslipPayables.PayslipPayable do
  use Sig.Schema

  alias Sig.Finance.Payables.Payable
  alias Sig.HR.Payslips.Payslip
  alias Sig.Organizations.Org

  @primary_key false
  schema "payslip_payables" do
    belongs_to :org, Org, primary_key: true
    belongs_to :payslip, Payslip, primary_key: true
    belongs_to :payable, Payable, primary_key: true

    field :is_auto_adjustable_amount, :boolean
  end
end
