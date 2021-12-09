defmodule Sig.HR.Registrations.Warnings.Warning do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_warnings" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :date, :date
    field :description, :string

    timestamps()
  end

  @fields [:org_id, :registration_id, :date, :description]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:description, max: 255)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:date, :description])
    |> validate_required([:date, :description])
    |> validate_length(:description, max: 255)
  end
end
