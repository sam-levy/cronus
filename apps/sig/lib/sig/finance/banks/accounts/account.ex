defmodule Sig.Finance.Banks.Accounts.Account do
  use Sig.Schema

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
    field :is_active, :boolean, default: true
    field :is_joint_account, :boolean, default: false

    timestamps()
  end

  @create_required_fields [:org_id, :type, :routing_number, :branch_number, :number]
  @create_fields @create_required_fields ++ [:pix_key, :other_info, :is_active, :is_joint_account]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_routing_number(:routing_number)
    |> validate_length(:branch_number, max: 255)
    |> validate_length(:number, max: 255)
    |> pix_key_validations()
    |> unique_constraint([:routing_number, :branch_number, :number, :org_id],
      name: :bank_accounts_org_id_account
    )
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    target
    |> cast(attrs, [:pix_key, :is_active])
    |> pix_key_validations()
  end

  defp pix_key_validations(changeset) do
    changeset
    |> validate_format(:pix_key, ~r/^\S*$/, message: "can not have white spaces")
    |> validate_length(:pix_key, max: 255)
    |> unique_constraint([:pix_key, :org_id])
  end
end
