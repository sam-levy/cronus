defmodule SigLive.EmployeeRegistrations.Show do
  use SigLive, :surface_live_view
  use SigLive.PayslipsState

  on_mount SigLive.InitAssigns

  alias Surface.Components.LivePatch

  alias Sig.Entities
  alias Sig.Finance
  alias Sig.HR

  alias SigLive.EmployeeRegistrations.{
    Salaries,
    Benefits,
    Warnings,
    Overtimes,
    Suspensions,
    LeavePeriods,
    RecurringPayslipItems,
    Payslips
  }

  @impl true
  def mount(%{"entity_id" => entity_id, "id" => id}, _session, socket) do
    %{org: org} = socket.assigns
    individual = Entities.get_individual(org, entity_id)

    socket =
      assign(
        socket,
        individual: individual,
        registration: HR.get_registration(individual, id),
        assigns_built_for: [],
        payslips: [],
        selected_payslip: nil,
        overtimes: [],
        selected_payslip_items: [],
        selected_payslip_payables: [],
        recurring_payslip_items: []
      )

    {:ok, socket,
     temporary_assigns: [
       salaries: [],
       benefits: [],
       warnings: [],
       suspensions: [],
       leave_periods: [],
       recurring_payslip_items: nil
     ]}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    %{live_action: screen, assigns_built_for: assigns_built_for} = socket.assigns

    if screen in assigns_built_for do
      {:noreply, assign(socket, :active_screen, screen)}
    else
      {:noreply,
       socket
       |> build_assigns_for(screen)
       |> assign(:active_screen, screen)}
    end
  end

  defp build_assigns_for(socket, :registration_show) do
    %{registration: registration, assigns_built_for: assigns_built_for} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_registration_salaries(registration)
      HR.subscribe_to_registration_benefits(registration)
      HR.subscribe_to_registration_warnings(registration)
      HR.subscribe_to_registration_overtimes(registration)
      HR.subscribe_to_registration_suspensions(registration)
      HR.subscribe_to_registration_leave_periods(registration)
      HR.subscribe_to_registration_recurring_payslip_items(registration)
    end

    assign(
      socket,
      salaries: HR.list_salaries_by_registration(registration),
      benefits: HR.list_benefits_by_registration(registration),
      warnings: HR.list_warnings_by_registration(registration),
      overtimes: HR.list_overtimes_by_registration(registration),
      suspensions: HR.list_suspensions_by_registration(registration),
      leave_periods: HR.list_leave_periods_by_registration(registration),
      recurring_payslip_items: HR.list_recurring_payslip_items_by_registration(registration),
      assigns_built_for: [:registration_show | assigns_built_for]
    )
  end

  defp build_assigns_for(socket, :payslips) do
    %{registration: registration, assigns_built_for: assigns_built_for} = socket.assigns

    payslips = HR.list_payslips_by(registration)
    selected_payslip = List.first(payslips)

    if connected?(socket) do
      HR.subscribe_to_payslips(registration)

      if selected_payslip, do: subscribe_to_payslip_subscriptions(selected_payslip)
    end

    socket
    |> assign(:payslips, payslips)
    |> assign_selected_payslip(selected_payslip)
    |> assign(:assigns_built_for, [:payslips | assigns_built_for])
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_info({:updated_registration_salaries, salaries}, socket) do
    {:noreply, assign(socket, salaries: salaries)}
  end

  @impl true
  def handle_info({:updated_registration_benefits, benefits}, socket) do
    {:noreply, assign(socket, benefits: benefits)}
  end

  @impl true
  def handle_info({:updated_registration_warnings, warnings}, socket) do
    {:noreply, assign(socket, warnings: warnings)}
  end

  @impl true
  def handle_info({:updated_registration_overtimes, overtimes}, socket) do
    {:noreply, assign(socket, overtimes: overtimes)}
  end

  @impl true
  def handle_info({:updated_registration_suspensions, suspensions}, socket) do
    {:noreply, assign(socket, suspensions: suspensions)}
  end

  @impl true
  def handle_info({:updated_registration_leave_periods, leave_periods}, socket) do
    {:noreply, assign(socket, leave_periods: leave_periods)}
  end

  @impl true
  def handle_info({:updated_registration_recurring_payslip_items, items}, socket) do
    {:noreply, assign(socket, recurring_payslip_items: items)}
  end

  @impl true
  def handle_event("select_payslip", %{"payslip_id" => id}, socket) do
    payslip = HR.get_payslip(socket.assigns.registration, id)

    unsubscribe_from_payslip_subscriptions(socket.assigns.selected_payslip)
    subscribe_to_payslip_subscriptions(payslip)

    {:noreply, assign_selected_payslip(socket, payslip)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="flex justify-between items-center mt-4">
        <div class="text-lg text-gray-500 font-medium tracking-wider">
          {@individual.name}
        </div>

        <div class="flex flex-row justify-end space-x-4">
          <LivePatch
            to={Routes.sig_employee_registrations_show_path(@socket, :registration_show, @individual.org_id, @individual.entity_id, @registration)}
            class={tab_classes_for(:registration_show, @active_screen)}
          >
            Cadastro
          </LivePatch>

          <LivePatch
            to={Routes.sig_employee_registrations_show_path(@socket, :payslips, @individual.org_id, @individual.entity_id, @registration)}
            class={tab_classes_for(:payslips, @active_screen)}
          >
            Holerites
          </LivePatch>
        </div>
      </div>

      <div :show={@active_screen == :registration_show} class="mt-4">
        <RecurringPayslipItems.List id="recurring_payslip_items_list" {=@registration} {=@recurring_payslip_items}/>
        <Salaries.List id="benefit_list" {=@registration} {=@salaries}/>
        <Benefits.List id="salary_list" {=@registration} {=@benefits}/>
        <Warnings.List id="warning_list" {=@registration} {=@warnings}/>
        <Overtimes.List id="warning_list" {=@registration} {=@overtimes}/>
        <Suspensions.List id="suspension_list" {=@registration} {=@suspensions}/>
        <LeavePeriods.List id="leave_period_list" {=@registration} {=@leave_periods}/>
      </div>

      <div :show={@active_screen == :payslips} class="mt-4">
        <Payslips
          id="payslips"
          select_payslip="select_payslip"
          entity={@individual.entity}
          {=@current_user}
          {=@registration}
          {=@payslips}
          {=@selected_payslip}
          {=@selected_payslip_items}
          {=@selected_payslip_payables}
        />
      </div>
    </div>
    """
  end

  @impl SigLive.PayslipsState
  def sort_payslips(payslips), do: Enum.sort_by(payslips, & &1.start_date, {:desc, Date})

  defp tab_classes_for(screen, screen) do
    ~w(text-purple-500 bg-purple-300 bg-opacity-75) ++ tab_base_classes()
  end

  defp tab_classes_for(_screen, _active_screen) do
    ~w(cursor-pointer text-gray-500 hover:bg-purple-300 hover:bg-opacity-75 hover:text-purple-500) ++
      tab_base_classes()
  end

  defp tab_base_classes, do: ~w(py-2 px-4 text-sm rounded-md select-none)
end
