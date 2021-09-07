defmodule Sig.Organizations.Entities.Entity do
  use Sig.Schema

  alias Sig.Organizations.Entities.Individual
  alias Sig.Organizations.Organization

  schema "entities" do
    belongs_to :organization, Organization

    has_one :individual, Individual, on_replace: :update

    timestamps()
  end

  def new_individual_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:organization_id])
    |> validate_required([:organization_id])
    |> cast_assoc(:individual, with: &Individual.new_changeset/2, required: true)
    |> assoc_constraint(:organization)
  end
end
