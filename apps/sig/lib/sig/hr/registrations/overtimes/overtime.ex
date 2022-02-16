defmodule Sig.HR.Registrations.Overtimes.Overtime do
  use Sig.Schema

  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "employee_overtimes" do
    belongs_to :org, Org, primary_key: true

    field :date, :date
    field :hours_amount, :string, default: Sig.Hour.new()

    belongs_to :registration, Registration
    belongs_to :payslip, Payslip

    timestamps()
  end

  @create_required_fields [:org_id, :date, :hours_amount, :registration_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_required_fields ++ [:payslip_id])
    |> validate_required(@create_required_fields)
    |> Sig.Hour.Changeset.validate_hours(:hours_amount)
    |> validate_beginning_of_month(:date)
    |> unique_constraint([:date, :registration_id, :org_id],
      name: :employee_overtimes_date_registration_unique
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:date, :hours_amount])
    |> validate_required([:date, :hours_amount])
    |> Sig.Hour.Changeset.validate_hours(:hours_amount)
    |> validate_beginning_of_month(:date)
    |> unique_constraint([:date, :registration_id, :org_id],
      name: :employee_overtimes_date_registration_unique
    )
  end

  def assign_payslip_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:payslip_id])
    |> validate_required([:payslip_id])
    |> assoc_constraint(:payslip)
  end

  def drop_payslip_changeset(%__MODULE__{} = target) do
    target
    |> cast(%{}, [])
    |> put_change(:payslip_id, nil)
  end
end
