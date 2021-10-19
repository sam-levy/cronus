defmodule Sig.HR.Registrations.Benefits.Benefit do
  use Sig.Schema

  alias Sig.Finance.HistoricalAmount
  alias Sig.HR.BenefitModels.BenefitModel
  alias Sig.HR.BenefitModels.BenefitType
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_benefits" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :description, :string
    field :benefit_type, BenefitType
    field :benefit_amount, Money.Ecto.Amount.Type
    field :benefit_amount_date, :date
    field :is_for_dependent, :boolean
    field :start_date, :date
    field :end_date, :date
    field :is_from_model, :boolean

    belongs_to :benefit_model, BenefitModel

    embeds_many :benefit_historical_amounts, HistoricalAmount

    field :type, BenefitType, virtual: true
    field :amount, Money.Ecto.Amount.Type, virtual: true

    timestamps()
  end

  @create_base_required_fields [
    :org_id,
    :registration_id,
    :is_for_dependent,
    :start_date
  ]

  @create_required_fields @create_base_required_fields ++ [:benefit_type, :benefit_amount]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_required_fields ++ [:description])
    |> validate_required(@create_required_fields)
    |> put_change(:is_from_model, false)
    |> validate_length(:description, max: 255)
    |> validate_money(:benefit_amount, :gt, 0)
    |> copy_change_value(:start_date, :benefit_amount_date)
    |> HistoricalAmount.add(:benefit_amount, :benefit_amount_date, :benefit_historical_amounts)
  end

  def create_from_model_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_base_required_fields ++ [:description, :benefit_model_id])
    |> validate_required(@create_base_required_fields ++ [:benefit_model_id])
    |> put_change(:is_from_model, true)
    |> validate_length(:description, max: 255)
    |> assoc_constraint(:benefit_model, name: :employee_benefits_benefit_model)
  end

  def update_benefit_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:benefit_amount, :benefit_amount_date])
    |> validate_required([:benefit_amount, :benefit_amount_date])
    |> validate_is_active(:end_date)
    |> validate_money(:benefit_amount, :gt, 0)
    |> HistoricalAmount.add(:benefit_amount, :benefit_amount_date, :benefit_historical_amounts)
  end

  def finalize_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:end_date])
    |> validate_required([:end_date])
    |> validate_is_active(:end_date)
    |> validate_dates(:end_date, :gt, :start_date)
  end
end
