defmodule SigWeb.PageController do
  use SigWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
