defmodule SigLive.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(403)
    |> json(%{error: "Forbidden"})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json(%{error: "Not found"})
  end

  def call(conn, {:error, error}) do
    conn
    |> put_status(400)
    |> json(%{error: error})
  end
end
