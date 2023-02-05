defmodule Sig.Accounting.LedgerCategories.LedgerCategory do
  use Sig.Schema

  alias Sig.Accounting.ChartOfAccounts.ChartOfAccount
  alias Sig.Organizations.Org

  schema "ledger_categories" do
    belongs_to :org, Org, primary_key: true

    field :code, :string
    field :description, :string
    field :entry_type, Sig.EntryType

    belongs_to :chart_of_account, ChartOfAccount

    timestamps()
  end

  @fields [
    :org_id,
    :code,
    :description,
    :entry_type,
    :chart_of_account_id
  ]

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_numericality(:code)
    |> validate_length(:code, max: 255)
    |> validate_length(:description, max: 255)
    |> assoc_constraint(:chart_of_account)
    |> unique_constraint([:code, :chart_of_account_id, :org_id],
      name: :ledger_categories_code_chart_of_account_id_unique
    )
    |> unique_constraint([:description, :chart_of_account_id, :org_id],
      name: :ledger_categories_description_chart_of_account_id_unique
    )
  end
end
