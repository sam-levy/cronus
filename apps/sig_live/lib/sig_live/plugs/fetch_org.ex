defmodule SigLive.Plugs.FetchOrg do
  @behaviour Plug

  import Plug.Conn

  alias Sig.Organizations
  alias SigLive.Fallback

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%{params: %{"org_id" => org_id}} = conn, _opts) do
    case Organizations.fetch_org(org_id) do
      {:ok, org} ->
        assign(conn, :org, org)

      {:error, :not_found} ->
        conn
        |> Fallback.call({:error, :not_found})
        |> halt()
    end
  end

  @impl Plug
  def call(conn, _opts), do: conn
end
