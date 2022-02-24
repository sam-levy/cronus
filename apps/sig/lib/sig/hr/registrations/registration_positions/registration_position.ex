defmodule Sig.HR.Registrations.RegistrationPositions.RegistrationPosition do
  use Sig.Schema

  alias Sig.Organizations.Org
  alias Sig.Organizations.Position
  alias Sig.HR.Registrations.Registration

  schema "registration_org_positions" do
    belongs_to :org, Org, primary_key: true

    field :start_date, :date

    belongs_to :registration, Registration
    belongs_to :position, Position

    timestamps()
  end

  @fields [:org_id, :start_date, :registration_id, :position_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:position)
    |> unique_constraint([:start_date, :org_position_id, :registration_id, :org_id],
      name: :registration_org_positions_start_date
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:position_id, :start_date])
    |> assoc_constraint(:position)
    |> unique_constraint([:start_date, :org_position_id, :registration_id, :org_id],
      name: :registration_org_positions_start_date
    )
  end
end
