defmodule SigLive.Individuals.Show do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Sig.Entities
  alias Sig.Finance
  alias Sig.HR

  alias SigLive.BankAccounts
  alias SigLive.EmployeeRegistrations

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    %{org: org} = socket.assigns
    individual = Entities.get_individual(org, id)

    if connected?(socket) do
      Finance.subscribe_to_bank_accounts(individual.entity)
      Finance.subscribe_to_entity_bank_accounts(individual.entity)
      HR.subscribe_to_individual_registrations(individual)
    end

    socket =
      assign(socket,
        individual: individual,
        bank_accounts: Finance.list_accounts_by_entity(individual.entity),
        entity_bank_accounts: Finance.list_entity_bank_accounts_by_entity(individual.entity),
        employee_registrations: HR.list_registrations_by(individual)
      )

    {:ok, socket, temporary_assigns: [employee_registrations: []]}
  end

  @impl true
  def handle_info({:updated_bank_accounts, bank_accounts}, socket) do
    {:noreply, assign(socket, bank_accounts: bank_accounts)}
  end

  @impl true
  def handle_info({:updated_entity_bank_accounts, entity_bank_accounts}, socket) do
    {:noreply, assign(socket, entity_bank_accounts: entity_bank_accounts)}
  end

  @impl true
  def handle_info({:updated_individual_registrations, individual_registrations}, socket) do
    {:noreply, assign(socket, employee_registrations: individual_registrations)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="my-7">
        <span class="text-gray-500 font-medium text-2xl tracking-wider">{@individual.name}</span>
      </div>

      <BankAccounts.List
        id="bank_accounts"
        entity={@individual.entity}
        {=@org}
        {=@bank_accounts}
        {=@entity_bank_accounts}
      />

      <EmployeeRegistrations.List
        id="employee_registrations"
        {=@org}
        {=@individual}
        {=@employee_registrations}
      />
    </div>
    """
  end
end
