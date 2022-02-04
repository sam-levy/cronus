defmodule Sig.StoresSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Sig.Accounts.UserStore, []},
      {Sig.Organizations.OrgStore, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
