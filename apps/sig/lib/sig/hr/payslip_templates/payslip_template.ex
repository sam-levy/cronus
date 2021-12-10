defmodule Sig.HR.PayslipTemplates.PayslipTemplate do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "payslip_templates" do
    belongs_to :org, Org, primary_key: true

    field :name, :string

    timestamps()
  end

  @create_fields [:org_id, :name]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_length(:name, max: 255)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
  end
end
