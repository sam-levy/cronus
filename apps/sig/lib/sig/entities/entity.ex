defmodule Sig.Entities.Entity do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual
  alias Sig.Organizations.Organization

  schema "entities" do
    belongs_to :organization, Organization, primary_key: true

    has_one :individual, Individual, on_replace: :update
    has_one :company, Company, on_replace: :update

    timestamps()
  end
end
