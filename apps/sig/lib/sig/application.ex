defmodule Sig.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Sig.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sig.PubSub}
      # Start a worker by calling: Sig.Worker.start_link(arg)
      # {Sig.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Sig.Supervisor)
  end
end
