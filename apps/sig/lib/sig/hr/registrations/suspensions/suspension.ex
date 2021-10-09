defmodule Sig.HR.Registrations.Suspensions.Suspension do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_suspensions" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :description, :string
    field :start_date, :date
    field :end_date, :date

    timestamps()
  end

  @fields [:org_id, :registration_id, :description, :start_date, :end_date]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:description, max: 255)
    |> validate_dates(:end_date, [:eq, :gt], :start_date)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:description, :start_date, :end_date])
    |> validate_length(:description, max: 255)
    |> validate_dates(:end_date, [:eq, :gt], :start_date)
  end
end
