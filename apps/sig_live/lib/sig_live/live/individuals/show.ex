defmodule SigLive.Individuals.Show do
  use SigLive, :surface_live_view

  alias Sig.Entities
  alias Sig.Finance
  alias Sig.HR

  alias SigLive.BankAccounts
  alias SigLive.Components.AppMenu
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
        org: org,
        individual: individual,
        bank_accounts: Finance.list_accounts_by(individual.entity),
        entity_bank_accounts: Finance.list_entity_bank_accounts_by_entity(individual.entity),
        employee_registrations:
          HR.list_registrations_by(individual, preload: [:registered_at, :salaries])
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
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu>
        <AppMenu.Breadcrumb noslash name="Pessoas" path={Routes.sig_individuals_index_path(@socket, :index, @org)} />
        <AppMenu.Breadcrumb name={@individual.name} />
      </AppMenu>

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
