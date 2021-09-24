defmodule Sig.Factories.EntityBankAccountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Banks
      alias Sig.Finance.Banks.Accounts.Account
      alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
      alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount.RelationshipWithHolder

      def factory(:entity_bank_account, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org))

        bank_account =
          Keyword.get(
            attrs,
            :bank_account,
            insert(:bank_account, org: org, entity: insert(:entity, org: org))
          )

        %EntityBankAccount{
          org: org,
          entity: entity,
          bank_account: bank_account,
          is_primary: false,
          is_joint_account_holder: false,
          relationship_with_holder: random_enum_value(RelationshipWithHolder)
        }
      end
    end
  end
end
