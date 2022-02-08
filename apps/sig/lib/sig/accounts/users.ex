defmodule Sig.Accounts.Users do
  use Sig.Query, schema: Sig.Accounts.User, as: :user

  import Sig.Broadcaster

  alias Ecto.Multi

  alias Sig.Accounts.{User, UserStore, UserToken}
  alias Sig.Organizations.Org
  alias Sig.Repo

  alias SigLive.UserAuth

  def list_users(%Org{} = org, opts \\ []) do
    org
    |> query_by()
    |> shallow_preload(opts)
    |> handle_order_by(opts, :email)
    |> Repo.all()
  end

  def disable_user(%User{} = user) do
    user_token_query =
      user
      |> UserToken.user_and_contexts_query(:all)
      |> select([user_token], user_token.token)

    Multi.new()
    |> Multi.update(:disable_user, User.disable_changeset(user))
    |> Multi.delete_all(:tokens, user_token_query)
    |> Multi.run(:delete_from_store, fn _, %{tokens: {_, tokens}} -> delete_from_store(tokens) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{disable_user: user, tokens: {_, tokens}}} ->
        disconnect_live_views(tokens)
        {:ok, user}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  defp delete_from_store(nil), do: {:ok, nil}
  defp delete_from_store(tokens), do: {:ok, UserStore.delete(tokens)}

  defp disconnect_live_views(tokens) do
    Enum.each(tokens, fn token ->
      token
      |> UserAuth.live_socket_id()
      |> UserAuth.disconnect_live_view()
    end)
  end

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
