defmodule Sig.HR.Registrations.Vouchers.Voucher do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  defenum(VoucherType, :employee_voucher_type, [:transport, :meal, :food])

  schema "employee_vouchers" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :type, VoucherType
    field :amount, Money.Ecto.Amount.Type
    field :start_date, :date
    field :end_date, :date

    timestamps()
  end

  @create_fields [:org_id, :registration_id, :type, :amount, :start_date]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_money(:amount)
  end
end
