defmodule Sig.Entities.Entity do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual
  alias Sig.Organizations.Org

  defenum(EntityType, :entity_type, [:individual, :company])

  schema "entities" do
    belongs_to :org, Org, primary_key: true

    field :type, EntityType

    has_one :company, Company
    has_one :individual, Individual

    timestamps()
  end
end
