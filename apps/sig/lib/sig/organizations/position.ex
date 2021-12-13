defmodule Sig.Organizations.Position do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "org_positions" do
    belongs_to :org, Org, primary_key: true

    field :name, :string

    timestamps()
  end

  @fields [:org_id, :name]

  def changeset(%__MODULE__{} = target \\ %__MODULE__{}, %{} = attrs) do
    target
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:name, max: 255)
    |> unique_constraint([:name, :org_id])
  end
end
