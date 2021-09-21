defmodule Sig.Factories.EntityBankAccountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Banks
      alias Sig.Finance.Banks.Accounts.Account
      alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount

      def factory(:entity_bank_account, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org))
        bank_account = Keyword.get(attrs, :bank_account, insert(:bank_account, org_id: org.id))

        %EntityBankAccount{
          org_id: org.id,
          entity: entity,
          bank_account: bank_account
        }
      end
    end
  end
end
