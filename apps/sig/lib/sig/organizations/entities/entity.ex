defmodule Sig.Organizations.Entities.Entity do
  use Sig.Schema

  alias Sig.Organizations.Entities.{Company, Individual}

  schema "entities" do
    has_one :individual, Individual, on_replace: :update
    has_one :company, Company, on_replace: :update

    timestamps()
  end
end
