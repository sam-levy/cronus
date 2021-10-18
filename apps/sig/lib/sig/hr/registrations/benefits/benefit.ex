defmodule Sig.HR.Registrations.Benefits.Benefit do
  use Sig.Schema

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
    field :is_for_dependent, :boolean
    field :start_date, :date
    field :end_date, :date
    field :is_from_model, :boolean

    belongs_to :benefit_model, BenefitModel

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
  end

  def create_from_model_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_base_required_fields ++ [:description, :benefit_model_id])
    |> validate_required(@create_base_required_fields ++ [:benefit_model_id])
    |> put_change(:is_from_model, true)
    |> validate_length(:description, max: 255)
    |> assoc_constraint(:benefit_model, name: :employee_benefits_benefit_model)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:end_date])
    |> validate_required([:end_date])
    |> validate_dates(:end_date, :gt, :start_date)
  end

  # TODO: Add benefit_amount_start_date and benefit_historical_amounts
end
