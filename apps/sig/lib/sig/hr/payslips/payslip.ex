defmodule Sig.HR.Payslips.Payslip do
  use Sig.Schema

  alias Sig.HR.Payslips.Groups.Group
  alias Sig.HR.Payslips.PayslipGroupType
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  schema "payslips" do
    belongs_to :org, Org, primary_key: true

    field :type, PayslipGroupType
    field :amount, Money.Ecto.Amount.Type
    field :start_date, :date
    field :end_date, :date
    field :is_closed, :boolean

    belongs_to :group, Group
    belongs_to :registration, Registration

    timestamps()
  end

  @create_fields [
    :org_id,
    :type,
    :start_date,
    :end_date,
    :registration_id
  ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_dates(:end_date, :gt, :start_date)
  end

  @update_fields [:type, :start_date, :end_date]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
    |> validate_dates(:end_date, :gt, :start_date)
  end

  def update_amount_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
    |> validate_money(:amount, [:eq, :gt], 0)
  end

  def update_is_closed_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:is_closed])
    |> validate_required([:is_closed])
  end

  def assign_group(
        %Ecto.Changeset{valid?: true, data: %__MODULE__{}, changes: %{org_id: org_id, type: type}} =
          changeset,
        %Group{org_id: org_id, type: type} = group
      ) do
    with payslip_beginning_of_month <- Date.beginning_of_month(changeset.changes.start_date),
         :eq <- Date.compare(group.date, payslip_beginning_of_month) do
      put_change(changeset, :group_id, group.id)
    else
      _ -> changeset
    end
  end

  def assign_group(changeset, _group), do: changeset
end
