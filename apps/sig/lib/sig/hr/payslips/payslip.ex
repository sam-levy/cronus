defmodule Sig.HR.Payslips.Payslip do
  use Sig.Schema

  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.PayslipGroupType
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "payslips" do
    belongs_to :org, Org, primary_key: true

    field :type, PayslipGroupType
    field :amount, Money.Ecto.Amount.Type
    field :start_date, :date
    field :end_date, :date
    field :is_closed, :boolean

    belongs_to :group, Group
    belongs_to :registration, Registration

    timestamps()
  end

  @create_fields [
    :org_id,
    :type,
    :start_date,
    :end_date,
    :group_id,
    :registration_id
  ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_dates(:end_date, :gt, :start_date)
  end

  def update_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> validate_money(:amount, :gt, 0)
  end
end
