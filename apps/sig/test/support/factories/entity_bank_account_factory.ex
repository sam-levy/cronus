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
          Keyword.get(attrs, :bank_account, insert(:bank_account, org: org, entity: entity))

        %EntityBankAccount{
          org: org,
          entity: entity,
          bank_account: bank_account
        }
      end

      def random_enum_value(:relationship_with_holder) do
        random_enum_value(RelationshipWithHolder)
      end
    end
  end
end
