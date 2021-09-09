defmodule Sig.Organizations.Entities.Entity do
  use Sig.Schema

  alias Sig.Organizations.Entities.{Company, Individual}

  schema "entities" do
    has_one :individual, Individual, on_replace: :update
    has_one :company, Company, on_replace: :update

    timestamps()
  end

  def new_individual_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [])
    |> cast_assoc(:individual, with: &Individual.new_changeset/2, required: true)
  end

  def new_real_company_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [])
    |> cast_assoc(:company, with: &Company.new_real_changeset/2, required: true)
  end

  def new_virtual_company_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [])
    |> cast_assoc(:company, with: &Company.new_virtual_changeset/2, required: true)
  end
end
