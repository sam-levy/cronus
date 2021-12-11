defmodule Sig.HR.Payslips.Categories.Category do
  use Sig.Schema

  alias Sig.Organizations.Org

  schema "payslip_categories" do
    belongs_to :org, Org, primary_key: true

    field :code, :string
    field :description, :string
    field :entry_type, Sig.EntryType
    field :is_payment_advance, :boolean

    timestamps()
  end

  @create_required_fields [:org_id, :code, :description, :entry_type]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_required_fields ++ [:is_payment_advance])
    |> validate_required(@create_required_fields)
    |> base_validations()
  end

  @update_required_fields [:code, :description, :entry_type]

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, @update_required_fields ++ [:is_payment_advance])
    |> validate_required(@update_required_fields)
    |> base_validations()
  end

  defp base_validations(changeset) do
    changeset
    |> validate_length(:code, max: 255)
    |> validate_length(:description, max: 255)
    |> handle_is_payment_advance()
    |> unique_constraint(:code, name: :payslip_categories_code_unique)
  end

  defp handle_is_payment_advance(%{valid?: true} = changeset) do
    with {_, :credit} <- fetch_field(changeset, :entry_type),
         {_, true} <- fetch_field(changeset, :is_payment_advance) do
      put_change(changeset, :is_payment_advance, nil)
    else
      _ -> changeset
    end
  end

  defp handle_is_payment_advance(changeset), do: changeset
end
