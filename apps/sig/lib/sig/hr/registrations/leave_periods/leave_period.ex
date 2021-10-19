defmodule Sig.HR.Registrations.LeavePeriods.LeavePeriod do
  use Sig.Schema

  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  defenum(LeavePeriodType, :gender, [:maternity_leave, :medical_license])

  schema "employee_leave_periods" do
    belongs_to :org, Org, primary_key: true
    belongs_to :registration, Registration, primary_key: true

    field :type, LeavePeriodType
    field :start_date, :date
    field :end_date, :date

    timestamps()
  end

  @fields [:org_id, :registration_id, :type, :start_date, :end_date]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_dates(:end_date, :gt, :start_date)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:type, :start_date, :end_date])
    |> validate_dates(:end_date, :gt, :start_date)
  end
end
