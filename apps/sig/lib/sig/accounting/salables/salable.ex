defmodule Sig.Accounting.Salables.Salable do
  use Sig.Schema

  alias Sig.Entities.Entity
  alias Sig.Organizations.Org

  defenum(SalableType, :salable_type, [:good, :service])

  schema "salables" do
    belongs_to :org, Org, primary_key: true

    field :type, SalableType
    field :code, :string
    field :description, :string
    field :unit, :string

    belongs_to :entity, Entity

    timestamps()
  end

  @create_fields [:org_id, :type, :code, :description, :unit, :entity_id]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> assoc_constraint(:entity)
    |> base_validations()
  end

  @update_fields [:type, :code, :description, :unit]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> base_validations()
  end

  defp base_validations(changeset) do
    changeset
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 50)
    |> unique_constraint([:code, :entity_id, :org_id],
      name: :salables_code_entity_id_org_id_unique
    )
    |> unique_constraint([:description, :entity_id, :org_id],
      name: :salables_description_entity_id_org_id_unique
    )
  end
end
