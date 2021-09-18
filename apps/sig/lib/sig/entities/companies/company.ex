defmodule Sig.Entities.Companies.Company do
  use Sig.Schema

  alias BrazilianDocuments.Types.CNPJ

  alias Sig.Entities.Entity
  alias Sig.Organizations.Org

  @primary_key false
  schema "companies" do
    belongs_to :entity, Entity, primary_key: true
    belongs_to :org, Org, primary_key: true

    field :is_virtual, :boolean, default: false
    field :trade_name, :string
    field :registration_name, :string
    field :cnpj, CNPJ

    timestamps()
  end

  @real_company_fields [:entity_id, :org_id, :trade_name, :registration_name, :cnpj]
  @virtual_company_fields [:entity_id, :org_id, :trade_name]

  def create_real_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @real_company_fields)
    |> validate_required(@real_company_fields)
    |> base_validations()
    |> validate_length(:registration_name, max: 255)
    |> unique_constraint([:cnpj, :org_id])
    |> unique_constraint([:registration_name, :org_id])
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
    |> unique_constraint([:trade_name, :org_id])
  end
end
