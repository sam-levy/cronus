defmodule Sig.Organizations.Entities.Individual do
  use Sig.Schema

  alias Sig.Organizations.Entities.Entity
  alias Sig.Organizations.Organization

  defenum(Gender, :gender, [:male, :female, :other])

  @primary_key false
  schema "individuals" do
    belongs_to :entity, Entity, primary_key: true

    field :name, :string
    field :cpf, :string
    field :gender, Gender

    belongs_to :organization, Organization

    timestamps()
  end

  @create_fields [:entity_id, :name, :gender, :cpf, :organization_id]
  @update_fields [:name, :gender]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> base_validations()
    |> validate_cpf(:cpf)
    |> validate_length(:cpf, max: 11)
    |> unique_constraint([:cpf, :organization_id])
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
    |> base_validations()
  end

  defp base_validations(changeset) do
    changeset
    |> validate_length(:name, max: 255)
    |> assoc_constraint(:entity)
    |> assoc_constraint(:organization)
  end
end
