defmodule SigLive.Plugs.AuthorizeOrgUser do
  @behaviour Plug

  import Plug.Conn

  alias Sig.Accounts
  alias SigLive.FallbackController

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%{assigns: %{current_user: user, org: org}} = conn, _opts) do
    if Accounts.authorized_org_user?(org, user) do
      conn
    else
      forbid(conn)
    end
  end

  @impl Plug
  def call(conn, _opts), do: forbid(conn)

  defp forbid(conn) do
    conn
    |> FallbackController.call({:error, :forbidden})
    |> halt()
  end
end
