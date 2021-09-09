defmodule Sig.Organizations.Entities.Company do
  use Sig.Schema

  alias Sig.Organizations.Entities.Entity
  alias Sig.Organizations.Organization

  @primary_key false
  schema "companies" do
    belongs_to :entity, Entity, primary_key: true

    field :is_virtual, :boolean, default: false
    field :trade_name, :string
    field :registration_name, :string
    field :cnpj, :string

    belongs_to :organization, Organization

    timestamps()
  end

  @real_company_fields [:entity_id, :trade_name, :organization_id, :registration_name, :cnpj]
  @virtual_company_fields [:entity_id, :trade_name, :organization_id]

  def create_real_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @real_company_fields)
    |> validate_required(@real_company_fields)
    |> base_validations()
    |> validate_cnpj(:cnpj)
    |> validate_length(:cnpj, max: 14)
    |> validate_length(:registration_name, max: 255)
    |> unique_constraint([:cnpj, :organization_id])
    |> unique_constraint([:registration_name, :organization_id])
  end

  def create_virtual_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @virtual_company_fields)
    |> validate_required(@virtual_company_fields)
    |> base_validations()
    |> put_change(:is_virtual, true)
  end

  defp base_validations(changeset) do
    changeset
    |> validate_length(:trade_name, max: 255)
    |> unique_constraint([:trade_name, :organization_id])
    |> assoc_constraint(:entity)
    |> assoc_constraint(:organization)
  end
end
