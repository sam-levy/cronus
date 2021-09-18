defmodule Sig.Entities.Individuals.Individual do
  use Sig.Schema

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Entity
  alias Sig.Organizations.Org

  defenum(Gender, :gender, [:male, :female, :other])

  @primary_key false
  schema "individuals" do
    belongs_to :entity, Entity, primary_key: true
    belongs_to :org, Org, primary_key: true

    field :name, :string
    field :cpf, CPF
    field :gender, Gender

    timestamps()
  end

  @create_fields [:entity_id, :org_id, :name, :gender, :cpf]
  @update_fields [:name, :gender]

  def cast_params(params) do
    cast(%__MODULE__{}, params, @create_fields ++ @update_fields).changes
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_fields)
    |> validate_length(:name, max: 255)
    |> unique_constraint([:cpf, :org_id])
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_fields)
    |> validate_required(@update_fields)
    |> validate_length(:name, max: 255)
  end
end
