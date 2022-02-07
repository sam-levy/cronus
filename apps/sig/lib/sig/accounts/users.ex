defmodule Sig.Accounts.Users do
  use Sig.Query, schema: Sig.Accounts.User, as: :user

  import Sig.Broadcaster

  alias Ecto.Multi

  alias Sig.Accounts.{User, UserStore, UserToken}
  alias Sig.Organizations.Org
  alias Sig.Repo

  def list_users(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(opts)
    |> handle_order_by(opts, :email)
    |> Repo.all()
  end

  def disable_user(%User{} = user) do
    Multi.new()
    |> Multi.update(:disable_user, User.disable_changeset(user))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Multi.run(:delete_from_store, fn _, %{tokens: {_, tokens}} -> delete_from_store(tokens) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{disable_user: user}} -> {:ok, user}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp delete_from_store(nil), do: {:ok, nil}
  defp delete_from_store(tokens), do: {:ok, UserStore.delete(tokens)}

  def enable_user(%User{} = user) do
    user
    |> User.enable_changeset()
    |> Repo.update()
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
