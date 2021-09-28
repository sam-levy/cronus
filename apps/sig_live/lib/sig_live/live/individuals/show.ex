defmodule SigLive.Individuals.Show do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Sig.Entities
  alias Sig.Finance

  alias SigLive.BankAccounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    %{org: org} = socket.assigns
    individual = Entities.get_individual(org, id)

    if connected?(socket), do: Finance.subscribe_to_bank_accounts(individual.entity)

    socket =
      assign(socket,
        individual: individual,
        bank_accounts: Finance.list_accounts_by_entity(individual.entity)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:updated_bank_accounts, bank_accounts}, socket) do
    {:noreply, assign(socket, bank_accounts: bank_accounts)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="my-7">
      <span class="text-gray-500 font-medium text-2xl tracking-wider">{@individual.name}</span>
    </div>

    <BankAccounts.List
      id="bank_accounts"
      accounts={@bank_accounts}
      entity={@individual.entity}
    />
    """
  end
end
