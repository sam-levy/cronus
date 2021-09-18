defmodule Sig.Organizations.Org do
  use Sig.Schema

  schema "orgs" do
    field :name, :string

    timestamps()
  end

  def changeset(target \\ %__MODULE__{}, attrs) do
    target
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
  end
end
