defmodule Sig.Accounting.ChartOfAccounts.ChartOfAccount do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "chart_of_accounts" do
    belongs_to :org, Org, primary_key: true

    field :name, :string

    timestamps()
  end

  @fields [:org_id, :name]

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_length(:name, max: 255)
    |> unique_constraint([:name, :org_id])
  end
end
