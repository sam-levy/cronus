defmodule Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount do
  use Sig.Schema

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Organizations.Org

  @individual_person_relationships [:child, :spouse, :partner]
  @individual_company_person_relationships [:company_owner]
  @company_company_person_relationships [:same_owner_company]

  defenum(
    RelationshipWithHolder,
    :relationship_with_bank_account_holder,
    @individual_person_relationships ++
      @individual_company_person_relationships ++
      @company_company_person_relationships
  )

  @primary_key false
  schema "entities_bank_accounts" do
    belongs_to :org, Org, primary_key: true
    belongs_to :entity, Entity, primary_key: true
    belongs_to :bank_account, Account, primary_key: true

    field :is_primary, :boolean
    field :is_joint_account_holder, :boolean
    field :relationship_with_holder, RelationshipWithHolder

    timestamps()
  end

  @fields [
    :org_id,
    :entity_id,
    :bank_account_id,
    :relationship_with_holder,
    :is_primary,
    :is_joint_account_holder
  ]

  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def update_changeset(%__MODULE__{} = target, attrs) do
    cast(target, attrs, [:is_primary])
  end

  def individual_person_relationships, do: @individual_person_relationships
  def individual_company_person_relationships, do: @individual_company_person_relationships
  def company_company_person_relationships, do: @company_company_person_relationships

  # TODO: Create a DB trigger with a stored procedure to
  # ensure there is always a record with is_primary = true
  # if a record exists for an entity.
end
