defmodule SigLive.Fallback do
  use Phoenix.Controller

  # TODO: Create nice error templates

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> text("400")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> text("403")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> text("404")
  end
end
