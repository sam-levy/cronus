defmodule Sig.Accounts.Users do
  use Sig.Query, schema: Sig.Accounts.User, as: :user

  import Sig.Broadcaster

  alias Sig.Organizations.Org
  alias Sig.Repo

  def list_users(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(opts)
    |> handle_order_by(opts, :email)
    |> Repo.all()
  end

  defp query_by(%Org{} = org) do
    where(init_query(), org_id: ^org.id)
  end

  def subscribe_to_users(%Org{} = org), do: subscribe(topic(org))

  def broadcast_users(%Org{} = org, opts \\ []) do
    broadcast(topic(org), {:updated_users, list_users(org, opts)})
  end

  defp topic(%Org{} = org), do: "org_id:" <> org.id <> ":users"
end
