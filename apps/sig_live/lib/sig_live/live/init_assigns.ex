defmodule SigLive.InitAssigns do
  import Phoenix.LiveView

  alias Sig.Accounts
  alias Sig.Organizations

  def on_mount(:default, %{"org_id" => org_id}, %{"user_token" => user_token}, socket) do
    socket =
      socket
      |> assign_new(:org, fn -> Organizations.get_org(org_id) end)
      |> assign_new(:current_user, fn -> Accounts.get_user_by_session_token(user_token) end)

    with %Organizations.Org{} <- socket.assigns.org,
         %Accounts.User{} <- socket.assigns.current_user do
      {:cont, socket}
    else
      nil -> {:halt, redirect(socket, to: "/users/log_in")}
    end
  end
end
