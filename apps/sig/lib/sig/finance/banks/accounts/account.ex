defmodule Sig.Finance.Banks.Accounts.Account do
  use Sig.Schema

  alias Sig.Entities.Entity
  alias Sig.Organizations.Org

  defenum(BankAccountType, :bank_account_type, [
    :checking_account,
    :savings_account,
    :salary_account
  ])

  schema "bank_accounts" do
    belongs_to :org, Org, primary_key: true

    field :type, BankAccountType
    field :routing_number, :string
    field :branch_number, :string
    field :number, :string
    field :other_info, :map, default: %{}
    field :pix_key, :string
    field :is_active, :boolean
    field :is_primary, :boolean
    field :is_joint_account, :boolean

    belongs_to :entity, Entity

    timestamps()
  end

  @create_required_fields [
    :org_id,
    :type,
    :routing_number,
    :branch_number,
    :number,
    :is_primary,
    :is_joint_account,
    :entity_id
  ]

  @create_fields @create_required_fields ++ [:pix_key, :other_info]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> put_change(:is_active, true)
    |> validate_routing_number(:routing_number)
    |> validate_length(:branch_number, max: 255)
    |> validate_length(:number, max: 255)
    |> validate_pix_key()
    |> assoc_constraint(:entity)
    |> unique_constraint([:number, :branch_number, :routing_number, :org_id],
      name: :bank_accounts_org_id_account
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:pix_key, :is_active, :is_primary])
    |> maybe_set_is_primary(target)
    |> validate_pix_key()
  end

  def is_primary_false_changeset(%__MODULE__{} = target) do
    cast(target, %{is_primary: false}, [:is_primary])
  end

  defp validate_pix_key(changeset) do
    changeset
    |> validate_format(:pix_key, ~r/^\S*$/, message: "can't have white spaces")
    |> validate_length(:pix_key, max: 255)
    |> unique_constraint([:pix_key, :org_id])
  end

  defp maybe_set_is_primary(changeset, %__MODULE__{is_primary: true}) do
    case get_change(changeset, :is_primary) do
      false -> put_change(changeset, :is_primary, true)
      _ -> changeset
    end
  end

  defp maybe_set_is_primary(changeset, _target), do: changeset
end
