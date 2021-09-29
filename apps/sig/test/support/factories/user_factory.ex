defmodule Sig.Factories.UserFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Accounts.User
      alias Sig.AccountsFixtures

      def factory(:user, attrs) do
        attrs = AccountsFixtures.valid_user_attributes(attrs)

        User.registration_changeset(%User{}, attrs)
      end
    end
  end
end
