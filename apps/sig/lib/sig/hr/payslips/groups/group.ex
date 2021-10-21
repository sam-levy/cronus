defmodule Sig.HR.Payslips.Groups.Group do
  use Sig.Schema

  alias Sig.HR.Payslips.PayslipGroupType
  alias Sig.Organizations.Org

  schema "payslip_groups" do
    belongs_to :org, Org, primary_key: true

    field :date, :date
    field :type, PayslipGroupType

    timestamps()
  end

  @fields [:org_id, :date, :type]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> ensure_beginning_of_month(:date)
  end

  defp ensure_beginning_of_month(changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, value} -> put_change(changeset, field, Date.beginning_of_month(value))
      :error -> changeset
    end
  end
end
