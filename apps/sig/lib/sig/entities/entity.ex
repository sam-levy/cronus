defmodule Sig.Entities.Entity do
  use Sig.Schema

  alias Sig.Organizations.Org

  defenum(EntityType, :entity_type, [:physical, :legal])

  schema "entities" do
    belongs_to :org, Org, primary_key: true

    field :type, EntityType

    timestamps()
  end
end
