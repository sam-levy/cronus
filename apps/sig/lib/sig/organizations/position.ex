defmodule Sig.Organizations.Position do
  use Sig.Schema

  alias Sig.Organizations.Org

  @primary_key false
  schema "org_positions" do
    field :name, :string, primary_key: true

    belongs_to :org, Org, primary_key: true

    timestamps()
  end
end
