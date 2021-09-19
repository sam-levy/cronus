defmodule Sig.Entities.Entity do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "entities" do
    belongs_to :org, Org, primary_key: true

    timestamps()
  end
end
