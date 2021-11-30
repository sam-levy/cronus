defmodule Sig.Finance.Banks do
  import Ecto.Query

  alias Sig.Finance.Banks.Bank
  alias Sig.Finance.Banks.Accounts
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.EntityBankAccounts
  alias Sig.Finance.Banks.EntityBankAccounts.EntityBankAccount
  alias Sig.Entities.Entity
  alias Sig.Repo

  banks_file = Application.app_dir(:sig, "priv/assets/brazilian-banks.json")
  @external_resource banks_file

  banks =
    banks_file
    |> File.read!()
    |> Jason.decode!()

  @all_banks Enum.map(banks, fn bank ->
               %Bank{
                 name: bank["LongName"],
                 routing_number: bank["COMPE"]
               }
             end)

  @banks_by_routing_number Map.new(@all_banks, &{&1.routing_number, &1})

  def list_banks, do: @all_banks

  def fetch_bank(routing_number) do
    case Map.get(@banks_by_routing_number, routing_number) do
      %Bank{} = bank -> {:ok, bank}
      nil -> {:error, :not_found}
    end
  end

  def valid_routing_number?(routing_number) do
    Map.has_key?(@banks_by_routing_number, routing_number)
  end

  def list_active_bank_accounts_by_entity(%Entity{} = entity) do
    Account
    |> join(:left, [account], eba in EntityBankAccount, on: eba.bank_account_id == account.id)
    |> where([account, eba], account.entity_id == ^entity.id or eba.entity_id == ^entity.id)
    |> where(org_id: ^entity.org_id)
    |> where(is_active: true)
    |> order_by(:routing_number)
    |> Repo.all()
  end

  def fetch_entity_active_primary_bank_account(%Entity{} = entity) do
    case Accounts.fetch_entity_primary(entity) do
      {:ok, account} ->
        if account.is_active, do: {:ok, account}, else: {:error, :not_found}

      {:error, :not_found} ->
        case EntityBankAccounts.fetch_entity_primary(entity) do
          {:ok, %{bank_account: account}} ->
            if account.is_active, do: {:ok, account}, else: {:error, :not_found}

          {:error, :not_found} ->
            {:error, :not_found}
        end
    end
  end
end
