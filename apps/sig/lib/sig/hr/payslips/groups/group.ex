defmodule Sig.HR.Payslips.Groups.Group do
  use Sig.Schema

  alias Sig.HR.Payslips.PayslipGroupType
  alias Sig.Organizations.Org

  schema "payslip_groups" do
    belongs_to :org, Org, primary_key: true

    field :date, :date
    field :type, PayslipGroupType

    timestamps()
  end
end
