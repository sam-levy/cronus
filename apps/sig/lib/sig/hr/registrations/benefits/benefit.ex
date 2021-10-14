defmodule Sig.HR.Registrations.Benefits.Benefit do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  defenum(BenefitType, :employee_benefit_type, [
    :meal_voucher,
    :food_voucher,
    :transportation_voucher,
    :employee_health_insurance,
    :employee_dependents_health_insurance
  ])

  schema "employee_benefits" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :description, :string
    field :type, BenefitType
    field :amount, Money.Ecto.Amount.Type
    field :start_date, :date
    field :end_date, :date

    timestamps()
  end

  @create_required_fields [:org_id, :registration_id, :type, :amount, :start_date]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_required_fields ++ [:description])
    |> validate_length(:description, max: 255)
    |> validate_required(@create_required_fields)
    |> validate_money(:amount, :gt, 0)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:end_date])
    |> validate_required([:end_date])
    |> validate_dates(:end_date, :gt, :start_date)
  end
end
