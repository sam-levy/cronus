defmodule Sig.HR.Registrations.Registration do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual
  alias Sig.HR.Registrations.CompanyAssignments.CompanyAssignment
  alias Sig.HR.Registrations.Salaries.Salary
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

    field :number, :string
    field :e_social_number, :string
    field :admission_date, :date
    field :resignation_date, :date
    field :resignation_type, ResignationType

    belongs_to :sector, Sector
    belongs_to :position, Position
    belongs_to :individual, Individual, references: :entity_id
    belongs_to :registered_at, Company, references: :entity_id

    has_many :salaries, Salary
    has_many :company_assignments, CompanyAssignment

    field :salary_amount, Money.Ecto.Amount.Type, virtual: true
    field :assigned_company_entity_id, Ecto.UUID, virtual: true

    # TODO: Remove once Summary is removed
    has_many :assigned_companies, through: [:company_assignments, :assigned_company]

    timestamps()
  end

  @create_required_fields [
    :org_id,
    :number,
    :e_social_number,
    :admission_date,
    :sector_id,
    :position_id,
    :individual_id,
    :registered_at_id,
    :salary_amount
  ]

  @create_fields @create_required_fields ++ [:assigned_company_entity_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> maybe_put_assigned_company_entity_id()
    |> base_validations()
  end

  @update_fields [
    :number,
    :e_social_number,
    :admission_date,
    :sector_id,
    :position_id,
    :registered_at_id
  ]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> base_validations()
  end

  def resignation_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:resignation_date, :resignation_type])
    |> validate_required([:resignation_date, :resignation_type])
    |> validate_dates(:admission_date, :lt, :resignation_date)
  end

  def undo_resignation_changeset(%__MODULE__{} = target) do
    target
    |> cast(%{resignation_date: nil, resignation_type: nil}, [
      :resignation_date,
      :resignation_type
    ])
    |> unique_constraint([:registered_at_id, :individual_id, :org_id],
      name: :employee_registrations_resignation_date_is_null_unique,
      message: "Existe um registro em aberto para esta empresa"
    )
  end

  defp base_validations(changeset) do
    changeset
    |> validate_numericality(:number)
    |> validate_numericality(:e_social_number)
    |> assoc_constraint(:sector)
    |> assoc_constraint(:position)
    |> assoc_constraint(:registered_at)
    |> unique_constraint([:number, :org_id])
    |> unique_constraint([:e_social_number, :org_id])
    |> unique_constraint([:registered_at_id, :individual_id, :org_id],
      name: :employee_registrations_resignation_date_is_null_unique
    )
  end

  defp maybe_put_assigned_company_entity_id(changeset) do
    with true <- changeset.valid?,
         :error <- fetch_change(changeset, :assigned_company_entity_id),
         {:ok, registered_at_id} <- fetch_change(changeset, :registered_at_id) do
      put_change(changeset, :assigned_company_entity_id, registered_at_id)
    else
      _ -> changeset
    end
  end
end
