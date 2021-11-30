defmodule Sig.HR.Payslips.Categories.Category do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "payslip_categories" do
    belongs_to :org, Org, primary_key: true

    field :code, :string
    field :description, :string
    field :entry_type, Sig.EntryType
    field :is_payment_advance, :boolean

    timestamps()
  end
end
