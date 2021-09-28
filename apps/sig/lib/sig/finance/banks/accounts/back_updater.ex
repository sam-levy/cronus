defmodule Sig.Finance.Banks.Accounts.BackUpdater do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Repo

  # TODO: Add tests
  def handle_existing_primary_account(%Entity{} = entity, %{} = attrs) do
    entity
    |> Accounts.fetch_entity_primary()
    |> handle_account(attrs)
  end

  defp handle_account({:error, :not_found}, _attrs), do: {:ok, nil}

  defp handle_account({:ok, account}, %{is_primary: true}) do
    account
    |> Account.is_primary_false_changeset()
    |> Repo.update()
  end

  defp handle_account({:ok, account}, _attrs), do: {:ok, account}
end
