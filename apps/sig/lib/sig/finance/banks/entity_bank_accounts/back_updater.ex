defmodule Sig.Finance.Banks.EntityBankAccounts.BackUpdater do
  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Repo

  # TODO: Add tests
  def handle_existing_primary_eba(%Entity{} = entity, %{} = attrs) do
    entity
    |> EntityBankAccounts.fetch_entity_primary()
    |> handle_eba(attrs)
  end

  defp handle_eba({:error, :not_found}, _attrs), do: {:ok, nil}

  defp handle_eba({:ok, eba}, %{is_primary: true}) do
    eba
    |> EntityBankAccount.update_changeset(%{is_primary: false})
    |> Repo.update()
  end

  defp handle_eba({:ok, eba}, _attrs), do: {:ok, eba}
end
