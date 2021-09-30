defmodule Sig.HR.Registrations.Registration do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual
  alias Sig.Organizations.Org
  alias Sig.Organizations.Position
  alias Sig.Organizations.Sector

  defenum(ResignationType, :employee_resignation_type, [
    :resigned,
    :dismissal,
    :dismissal_due_cause
  ])

  schema "employee_registrations" do
    belongs_to :org, Org, primary_key: true

    field :admission_date, :date
    field :resignation_date, :date
    field :resignation_type, ResignationType

    belongs_to :sector, Sector
    belongs_to :position, Position
    belongs_to :individual, Individual, references: :entity_id
    belongs_to :registered_at, Company, references: :entity_id
    belongs_to :work_at, Company, references: :entity_id

    timestamps()
  end

  @create_fields [
    :org_id,
    :admission_date,
    :sector_id,
    :position_id,
    :individual_id,
    :registered_at_id,
    :work_at_id
  ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> assoc_constraint(:sector)
    |> assoc_constraint(:position)
    |> assoc_constraint(:registered_at)
    |> assoc_constraint(:work_at)
    |> unique_constraint([:registered_at_id, :individual_id, :org_id],
      name: :employee_registrations_resignation_date_is_null_unique
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:sector_id, :position_id, :work_at_id])
    |> assoc_constraint(:sector)
    |> assoc_constraint(:position)
    |> assoc_constraint(:work_at)
  end

  def resignation_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:resignation_date, :resignation_type])
    |> validate_required([:resignation_date, :resignation_type])
    |> validate_first_date_before_second(:admission_date, :resignation_date)
  end
end
