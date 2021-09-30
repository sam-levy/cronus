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
end
