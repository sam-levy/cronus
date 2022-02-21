defmodule Sig.HR.Registrations.CompanyAssignments.CompanyAssignment do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_company_assignments" do
    belongs_to :org, Org, primary_key: true

    field :start_date, :date

    belongs_to :registration, Registration
    belongs_to :assigned_company, Company, references: :entity_id

    timestamps()
  end

  @fields [:org_id, :start_date, :registration_id, :assigned_company_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:assigned_company)
    |> unique_constraint([:start_date, :assigned_company_id, :registration_id, :org_id],
      name: :employee_company_assignments_company_start_date
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:start_date, :assigned_company_id])
    |> assoc_constraint(:assigned_company)
    |> unique_constraint([:start_date, :assigned_company_id, :registration_id, :org_id],
      name: :employee_company_assignments_company_start_date
    )
  end
end
