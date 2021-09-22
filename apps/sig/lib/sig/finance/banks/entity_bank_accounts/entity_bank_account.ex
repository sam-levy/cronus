defmodule Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount do
  use Sig.Schema

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Organizations.Org

  defenum(RelationshipWithHolder, :relationship_with_bank_account_holder, [
    :child,
    :spouse,
    :partner
  ])

  @primary_key false
  schema "entities_bank_accounts" do
    belongs_to :org, Org, primary_key: true
    belongs_to :entity, Entity, primary_key: true
    belongs_to :bank_account, Account, primary_key: true

    field :is_primary, :boolean, default: false
    field :is_joint_account_holder, :boolean, default: true
    field :relationship_with_holder, RelationshipWithHolder

    timestamps()
  end

  @create_required_fields [:org_id, :entity_id, :bank_account_id]
  @create_fields @create_required_fields ++
                   [:is_primary, :is_joint_account_holder, :relationship_with_holder]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @create_fields)
    |> validate_required(@create_required_fields)
    |> validate_required_if(:is_joint_account_holder, false, [:relationship_with_holder])
    |> drop_change_if(:is_joint_account_holder, true, :relationship_with_holder)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    cast(target, attrs, [:is_primary])
  end

  # TODO: Create a DB trigger with a stored procedure to
  # ensure there is always a record with is_primary = true
  # if a record exists for an entity.
end
