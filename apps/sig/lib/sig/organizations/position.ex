defmodule Sig.Organizations.Position do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "org_positions" do
    belongs_to :org, Org, primary_key: true

    field :name, :string

    timestamps()
  end
end
