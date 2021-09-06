defmodule Sig.Repo do
  use Ecto.Repo,
    otp_app: :sig,
    adapter: Ecto.Adapters.Postgres
end
