defmodule Sig.HR.BenefitModels.BenefitModel do
  use Sig.Schema

  alias Sig.Finance.HistoricalAmount
  alias Sig.HR.BenefitModels.BenefitType
  alias Sig.Organizations.Org

  schema "employee_benefit_models" do
    belongs_to :org, Org, primary_key: true

    field :description, :string
    field :type, BenefitType
    field :amount, Money.Ecto.Amount.Type
    field :amount_date, :date
    field :disabled_at, :date

    embeds_many :historical_amounts, HistoricalAmount

    timestamps()
  end

  @create_fields [:org_id, :description, :type, :amount, :amount_date]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_length(:description, max: 255)
    |> validate_money(:amount, :gt, 0)
    |> unique_constraint(:description, name: :employee_benefit_models_unique_description)
    |> HistoricalAmount.add(:amount, :amount_date, :historical_amounts)
  end

  @update_fields [:description, :type]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
    |> validate_length(:description, max: 255)
    |> unique_constraint(:description, name: :employee_benefit_models_unique_description)
  end

  def update_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:amount, :amount_date])
    |> validate_required([:amount, :amount_date])
    |> validate_money(:amount, :gt, 0)
    |> HistoricalAmount.add(:amount, :amount_date, :historical_amounts)
  end

  def disable_changeset(%__MODULE__{disabled_at: nil} = target, attrs) do
    target
    |> cast(attrs, [:disabled_at])
    |> validate_required([:disabled_at])
  end

  def disable_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:disabled_at])
    |> add_error(:disabled_at, "is already filled")
  end

  def enable_changeset(%__MODULE__{} = target) do
    target
    |> cast(%{}, [:disabled_at])
    |> put_change(:disabled_at, nil)
  end
end
