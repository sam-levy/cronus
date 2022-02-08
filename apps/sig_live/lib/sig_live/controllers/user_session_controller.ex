defmodule SigLive.UserSessionController do
  use SigLive, :controller

  alias Sig.Accounts
  alias SigLive.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    with %{disabled_at: nil} = user <- Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      _ ->
        conn
        |> put_flash(:error, "Email ou senha invalido")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
