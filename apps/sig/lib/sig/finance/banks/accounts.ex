defmodule Sig.Finance.Banks.Accounts do
  import Ecto.Query

  alias Sig.Entities.Entity
  alias Sig.Finance.Banks.Accounts.Account
  alias Sig.Finance.Banks.Accounts.BackUpdater
  alias Sig.Repo

  defdelegate maybe_set_existing_primary_account_to_false(entity, attrs), to: BackUpdater

  def list_by_entity(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def get_entity_primary(%Entity{} = entity) do
    entity
    |> query_by_entity()
    |> where(is_primary: true)
    |> Repo.one()
  end

  defp query_by_entity(entity) do
    Account
    |> where(org_id: ^entity.org_id)
    |> where(entity_id: ^entity.id)
  end
end
