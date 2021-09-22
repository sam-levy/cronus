defmodule SigLive.InitAssigns do
  import Phoenix.LiveView

  alias Sig.Organizations

  def mount(%{"org_id" => org_id}, _session, socket) do
    socket =
      socket
      |> assign_new(:org, fn -> Organizations.get_org(org_id) end)

    with %Organizations.Org{} <- socket.assigns.org do
      {:cont, socket}
    else
      nil -> {:halt, redirect(socket, to: "/users/log_in")}
    end
  end
end
