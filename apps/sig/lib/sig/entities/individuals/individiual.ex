defmodule Sig.Entities.Individuals.Individual do
  use Sig.Schema

  alias BrazilianDocuments.Types.CPF

  alias Sig.Entities.Entity
  alias Sig.HR.Registrations.Registration
  alias Sig.Organizations.Org

  defenum(Gender, :gender, [:male, :female, :other])

  @primary_key false
  schema "individuals" do
    belongs_to :org, Org, primary_key: true
    belongs_to :entity, Entity, primary_key: true

    field :name, :string
    field :cpf, CPF
    field :gender, Gender

    has_many :registrations, Registration, references: :entity_id, foreign_key: :individual_id
    has_many :registered_at_companies, through: [:registrations, :registered_at]
    has_many :company_assignments, through: [:registrations, :company_assignments]
    has_many :assigned_companies, through: [:company_assignments, :assigned_company]

    timestamps()
  end

  @fields [:org_id, :entity_id, :cpf, :name, :gender]

  def cast_params(params) do
    cast(%__MODULE__{}, params, @fields).changes
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:name, max: 255)
    |> unique_constraint([:cpf, :org_id])
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:name, :gender])
    |> validate_length(:name, max: 255)
  end
end
