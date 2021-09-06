defmodule Sig.Organizations.Organization do
  use Sig.Schema

  schema "organizations" do
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
