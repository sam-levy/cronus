defmodule SigLive.PageController do
  use SigLive, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
