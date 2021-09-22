defmodule Sig.Factories.BankAccountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Banks
      alias Sig.Finance.Banks.Accounts.Account
      alias Sig.Finance.Banks.Accounts.Account.BankAccountType

      def random_bank_routing_number do
        %{routing_number: routing_number} = Banks.list_banks() |> Enum.random()
        routing_number
      end

      def factory(:bank_account, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        entity = Keyword.get(attrs, :entity, insert(:entity, org: org))

        %Account{
          org: org,
          entity: entity,
          type: random_enum_value(BankAccountType),
          routing_number: random_bank_routing_number(),
          branch_number: sequence(&"branch_number_#{&1}"),
          number: sequence(&"account_number_#{&1}"),
          pix_key: sequence(&"pix_key_#{&1}")
        }
      end
    end
  end
end
