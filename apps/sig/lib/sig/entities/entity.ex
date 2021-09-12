defmodule Sig.Entities.Entity do
  use Sig.Schema

  alias Sig.Entities.Companies.Company
  alias Sig.Entities.Individuals.Individual

  schema "entities" do
    has_one :individual, Individual, on_replace: :update
    has_one :company, Company, on_replace: :update

    timestamps()
  end
end
