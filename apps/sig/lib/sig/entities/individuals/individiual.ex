defmodule Sig.Entities.Individuals.Individual do
  use Sig.Schema

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Entity
  alias Sig.Organizations.Organization

  defenum(Gender, :gender, [:male, :female, :other])

  @primary_key false
  schema "individuals" do
    belongs_to :entity, Entity, primary_key: true

    field :name, :string
    field :cpf, CPF
    field :gender, Gender

    belongs_to :organization, Organization

    timestamps()
  end

  @create_fields [:entity_id, :name, :gender, :cpf, :organization_id]
  @update_fields [:name, :gender]

  def cast_params(params) do
    cast(%__MODULE__{}, params, @create_fields ++ @update_fields).changes
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> base_validations()
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
