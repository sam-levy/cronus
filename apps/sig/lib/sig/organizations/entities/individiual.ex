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

  @new_fields [:name, :gender, :cpf, :organization_id]
  @edit_fields [:name, :gender]

  def new_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @new_fields)
    |> validate_required(@new_fields)
    |> base_validations()
    |> validate_cpf(:cpf)
    |> validate_length(:cpf, max: 11)
    |> unique_constraint([:cpf, :organization_id])
  end

  def edit_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @edit_fields)
    |> validate_required(@edit_fields)
    |> base_validations()
  end

  defp base_validations(changeset) do
    changeset
    |> validate_length(:name, max: 255)
    |> assoc_constraint(:entity)
    |> assoc_constraint(:organization)
  end
end
