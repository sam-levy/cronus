defmodule Sig.Factories.BankAccountFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Banks
      alias Sig.Finance.Banks.Accounts.Account
      alias Sig.Finance.Banks.Accounts.Account.BankAccountType

      def factory(:bank_account, attrs) do
        org = Keyword.get(attrs, :org) || insert(:org)
        entity = Keyword.get(attrs, :entity) || insert(:entity, org: org)

        struct(
          %Account{
            org: org,
            entity: entity
          },
          attrs_for(:bank_account, attrs)
        )
      end

      def attrs_for(:bank_account, attrs) do
        Enum.into(attrs, %{
          type: random_enum_value(:bank_account_type),
          routing_number: random_bank_routing_number(),
          branch_number: sequence(&"branch_number_#{&1}"),
          number: sequence(&"account_number_#{&1}"),
          is_active: true,
          is_primary: false,
          is_joint_account: false
        })
      end

      def random_bank_routing_number do
        %{routing_number: routing_number} = Banks.list_banks() |> Enum.random()
        routing_number
      end

      def random_enum_value(:bank_account_type) do
        random_enum_value(BankAccountType)
      end
    end
  end
end
