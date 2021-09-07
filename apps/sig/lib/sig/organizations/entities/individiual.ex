defmodule Sig.Organizations.Entities.Individual do
  use Sig.Schema

  alias Sig.Organizations.Entities.Entity

  defenum(Gender, :gender, [:male, :female, :other])

  @primary_key false
  schema "individuals" do
    belongs_to :entity, Entity, primary_key: true

    field :name, :string
    field :cpf, :string
    field :gender, Gender

    timestamps()
  end

  @new_fields [:entity_id, :name, :gender, :cpf]
  @edit_fields [:name, :gender]

  def new_changeset(target \\ %__MODULE__{}, attrs) do
    target
    |> cast(attrs, @new_fields)
    |> validate_required(@new_fields)
    |> base_validations()
    |> validate_cpf(:cpf)
    |> unique_constraint(:cpf)
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
  end
end
