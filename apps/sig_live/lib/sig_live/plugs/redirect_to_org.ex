defmodule SigLive.Plugs.RedirectToOrg do
  import Phoenix.Controller, only: [redirect: 2]

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%{assigns: %{current_user: user}} = conn, _opts) do
    # TODO: Modify once multiple orgs are allowed
    case Map.keys(user.org_roles) do
      [org_id | _] -> redirect(conn, to: "/orgs/" <> org_id <> "/individuals")
      _ -> forbid(conn)
    end
  end

  @impl Plug
  def call(conn, _opts), do: forbid(conn)

  defp forbid(conn) do
    conn
    |> SigLive.FallbackController.call({:error, :forbidden})
    |> Plug.Conn.halt()
  end
end
