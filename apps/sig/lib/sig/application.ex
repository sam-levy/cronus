defmodule Sig.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Sig.Repo,
      {Phoenix.PubSub, name: Sig.PubSub},
      {Task.Supervisor, name: Sig.BroadcastSupervisor},
      Sig.StoresSupervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Sig.Supervisor)
  end
end
