defmodule SigLive.EmployeeRegistrations.Show do
  use SigLive, :surface_live_view
  use SigLive.PayslipsState

  alias Surface.Components.LivePatch

  alias Sig.Entities
  alias Sig.Finance
  alias Sig.HR

  alias SigLive.EmployeeRegistrations.{
    Summary,
    Salaries,
    Benefits,
    Warnings,
    Overtimes,
    Suspensions,
    LeavePeriods,
    CompanyAssignments,
    RecurringPayslipItems,
    RegistrationPositions,
    Payslips
  }

  alias SigLive.Components.AppMenu

  defp registration_tab_screens do
    [
      :registration_summary,
      :registration_recurring_payslip_items,
      :registration_overtimes,
      :registration_benefits,
      :registration_warnings,
      :registration_suspensions,
      :registration_leave_periods
    ]
  end

  @impl true
  def mount(%{"registration_id" => registration_id}, _session, socket) do
    %{org: org} = socket.assigns

    registration = HR.get_registration(org, registration_id, preload: [:org, :registered_at])

    individual = Entities.get_individual(org, registration.individual_id)

    if connected?(socket) do
      HR.subscribe_to_individual_registrations(individual)
    end

    socket =
      assign(
        socket,
        assigns_built_for: MapSet.new(),
        registration: registration,
        individual: individual,
        payslips: [],
        selected_payslip: nil,
        selected_payslip_items: [],
        selected_payslip_payables: [],
        registration_salaries: [],
        registration_positions: [],
        registration_company_assignments: [],
        registration_recurring_payslip_items: [],
        registration_overtimes: [],
        registration_benefits: [],
        registration_warnings: [],
        registration_suspensions: [],
        registration_leave_periods: []
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{live_action: screen, assigns_built_for: assigns_built_for} = socket.assigns

    if MapSet.member?(assigns_built_for, screen) do
      {:noreply, assign(socket, :active_screen, screen)}
    else
      {:noreply, build_assigns_for(socket, screen, params)}
    end
  end

  defp build_assigns_for(socket, :registration_summary, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_salaries(registration)
      HR.subscribe_to_registration_positions(registration)
      HR.subscribe_to_company_assignments(registration)
    end

    socket
    |> assign_active_screen(:registration_summary)
    |> assign(
      registration_salaries: HR.list_salaries_by_registration(registration),
      registration_positions: HR.list_registration_positions_by(registration),
      registration_company_assignments: HR.list_company_assignments_by(registration)
    )
  end

  defp build_assigns_for(socket, :registration_recurring_payslip_items, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_recurring_payslip_items(registration)
    end

    socket
    |> assign_active_screen(:registration_recurring_payslip_items)
    |> assign(
      registration_recurring_payslip_items:
        HR.list_recurring_payslip_items_by_registration(registration)
    )
  end

  defp build_assigns_for(socket, :registration_overtimes, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_overtimes(registration)
    end

    socket
    |> assign_active_screen(:registration_overtimes)
    |> assign(registration_overtimes: HR.list_overtimes_by_registration(registration))
  end

  defp build_assigns_for(socket, :registration_benefits, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_benefits(registration)
    end

    socket
    |> assign_active_screen(:registration_benefits)
    |> assign(registration_benefits: HR.list_benefits_by_registration(registration))
  end

  defp build_assigns_for(socket, :registration_warnings, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_warnings(registration)
    end

    socket
    |> assign_active_screen(:registration_warnings)
    |> assign(registration_warnings: HR.list_warnings_by_registration(registration))
  end

  defp build_assigns_for(socket, :registration_suspensions, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_suspensions(registration)
    end

    socket
    |> assign_active_screen(:registration_suspensions)
    |> assign(registration_suspensions: HR.list_suspensions_by_registration(registration))
  end

  defp build_assigns_for(socket, :registration_leave_periods, _params) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_registration_leave_periods(registration)
    end

    socket
    |> assign_active_screen(:registration_leave_periods)
    |> assign(registration_leave_periods: HR.list_leave_periods_by_registration(registration))
  end

  defp build_assigns_for(socket, :payslips, _params) do
    payslips = HR.list_payslips_by(socket.assigns.registration)
    selected_payslip = List.first(payslips)

    handle_payslips_assigns(socket, payslips, selected_payslip)
  end

  defp build_assigns_for(socket, :payslip, %{"payslip_id" => id}) do
    payslips = HR.list_payslips_by(socket.assigns.registration)
    selected_payslip = Enum.find(payslips, &(&1.id == id))

    handle_payslips_assigns(socket, payslips, selected_payslip)
  end

  defp assign_active_screen(socket, screen) do
    assign(
      socket,
      assigns_built_for: MapSet.put(socket.assigns.assigns_built_for, screen),
      active_screen: screen
    )
  end

  defp handle_payslips_assigns(socket, payslips, selected_payslip) do
    registration = socket.assigns.registration

    if connected?(socket) do
      HR.subscribe_to_payslips(registration)

      if selected_payslip, do: subscribe_to_payslip_subscriptions(selected_payslip)
    end

    socket
    |> assign_active_screen(:payslips)
    |> assign(:payslips, payslips)
    |> assign_selected_payslip(selected_payslip)
  end

  @impl true
  def handle_info({:updated_individual_registration, value}, socket) do
    if value.id == socket.assigns.registration.id do
      maybe_assign(socket, :registration_summary, :registration, value)
    end
  end

  @impl true
  def handle_info({:updated_registration_salaries, value}, socket) do
    maybe_assign(socket, :registration_summary, :registration_salaries, value)
  end

  @impl true
  def handle_info({:updated_registration_positions, value}, socket) do
    maybe_assign(socket, :registration_summary, :registration_positions, value)
  end

  @impl true
  def handle_info({:updated_registration_company_assignments, value}, socket) do
    maybe_assign(socket, :registration_summary, :registration_company_assignments, value)
  end

  @impl true
  def handle_info({:updated_registration_recurring_payslip_items, value}, socket) do
    maybe_assign(socket, :registration_recurring_payslip_items, value)
  end

  @impl true
  def handle_info({:updated_registration_overtimes, value}, socket) do
    maybe_assign(socket, :registration_overtimes, value)
  end

  @impl true
  def handle_info({:updated_registration_benefits, value}, socket) do
    maybe_assign(socket, :registration_benefits, value)
  end

  @impl true
  def handle_info({:updated_registration_warnings, value}, socket) do
    maybe_assign(socket, :registration_warnings, value)
  end

  @impl true
  def handle_info({:updated_registration_suspensions, value}, socket) do
    maybe_assign(socket, :registration_suspensions, value)
  end

  @impl true
  def handle_info({:updated_registration_leave_periods, value}, socket) do
    maybe_assign(socket, :registration_leave_periods, value)
  end

  defp maybe_assign(socket, screen, assign_key, assign_value) do
    if MapSet.member?(socket.assigns.assigns_built_for, screen) do
      {:noreply, assign(socket, assign_key, assign_value)}
    else
      {:noreply, socket}
    end
  end

  defp maybe_assign(socket, assign_key, assign_value) do
    if MapSet.member?(socket.assigns.assigns_built_for, assign_key) do
      {:noreply, assign(socket, assign_key, assign_value)}
    else
      {:noreply, socket}
    end
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
    <div class="mb-5">
      <div class="flex justify-between items-center mb-2">
        <AppMenu id="app_menu" {=@org}>
          <AppMenu.Breadcrumb noslash name="RH" />
          <AppMenu.Breadcrumb
            name="Pessoas"
            path={Routes.sig_individuals_index_path(@socket, :index, @org)}
          />
          <AppMenu.Breadcrumb
            name={@individual.name}
            path={Routes.sig_individuals_show_path(@socket, :show, @org, @individual.entity_id)}
          />
          <AppMenu.Breadcrumb name={"Registro " <> @registration.registered_at.trade_name} />
        </AppMenu>

        <div class="flex flex-row justify-end space-x-4">
          <LivePatch
            to={Routes.sig_employee_registrations_show_path(@socket, :registration_summary, @org, @registration)}
            replace
            class={tab_classes_for(@active_screen, registration_tab_screens())}
          >
            Cadastro
          </LivePatch>

          <LivePatch
            to={Routes.sig_employee_registrations_show_path(@socket, :payslips, @org, @registration)}
            replace
            class={tab_classes_for(@active_screen, [:payslips])}
          >
            Holerites
          </LivePatch>
        </div>
      </div>

      <div :show={@active_screen in registration_tab_screens()} class="flex space-x-5">
        <div class="w-1/5">
          <div class="space-y-0.5">
            <LivePatch
              to={Routes.sig_employee_registrations_show_path(@socket, :registration_summary, @org, @registration)}
              class={menu_item_classes_for(@active_screen, :registration_summary)}
              replace
            >
              Informações
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(
                @socket,
                :registration_recurring_payslip_items,
                @org,
                @registration
              )}
              class={menu_item_classes_for(@active_screen, :registration_recurring_payslip_items)}
              replace
            >
              Holerite Modelo
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(@socket, :registration_overtimes, @org, @registration)}
              class={menu_item_classes_for(@active_screen, :registration_overtimes)}
              replace
            >
              Horas Extras
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(@socket, :registration_benefits, @org, @registration)}
              class={menu_item_classes_for(@active_screen, :registration_benefits)}
              replace
            >
              Benefícios
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(@socket, :registration_warnings, @org, @registration)}
              class={menu_item_classes_for(@active_screen, :registration_warnings)}
              replace
            >
              Advertências
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(
                @socket,
                :registration_suspensions,
                @org,
                @registration
              )}
              class={menu_item_classes_for(@active_screen, :registration_suspensions)}
              replace
            >
              Suspensões
            </LivePatch>

            <LivePatch
              to={Routes.sig_employee_registrations_show_path(
                @socket,
                :registration_leave_periods,
                @org,
                @registration
              )}
              class={menu_item_classes_for(@active_screen, :registration_leave_periods)}
              replace
            >
              Licensas
            </LivePatch>
          </div>
        </div>

        <div class="w-4/5">
          <div :show={@active_screen == :registration_summary} class="space-y-7">
            <Summary
              id="registration_summary"
              :if={@active_screen == :registration_summary}
              {=@registration}
              {=@individual}
              {=@org}
            />

            <CompanyAssignments.List
              id="company_assignment"
              company_assignments={@registration_company_assignments}
              {=@registration}
              {=@org}
            />

            <div class="flex gap-6">
              <div class="w-1/2">
                <RegistrationPositions.List
                  id="registration_positions"
                  {=@registration_positions}
                  {=@registration}
                  {=@org}
                />
              </div>

              <div class="w-1/2">
                <Salaries.List id="registration_salaries" salaries={@registration_salaries} {=@registration} />
              </div>
            </div>
          </div>

          <div :show={@active_screen == :registration_recurring_payslip_items}>
            <RecurringPayslipItems.List
              id="registration_recurring_payslip_items"
              recurring_payslip_items={@registration_recurring_payslip_items}
              {=@registration}
            />
          </div>

          <div :show={@active_screen == :registration_overtimes}>
            <Overtimes.List
              id="registration_overtimes"
              overtimes={@registration_overtimes}
              {=@registration}
            />
          </div>

          <div :show={@active_screen == :registration_benefits}>
            <Benefits.List id="registration_benefits" benefits={@registration_benefits} {=@registration} />
          </div>

          <div :show={@active_screen == :registration_warnings}>
            <Warnings.List id="registration_warnings" warnings={@registration_warnings} {=@registration} />
          </div>

          <div :show={@active_screen == :registration_suspensions}>
            <Suspensions.List
              id="registration_suspensions"
              suspensions={@registration_suspensions}
              {=@registration}
            />
          </div>

          <div :show={@active_screen == :registration_leave_periods}>
            <LeavePeriods.List
              id="registration_leave_periods"
              leave_periods={@registration_leave_periods}
              {=@registration}
            />
          </div>
        </div>
      </div>

      <div :show={@active_screen in [:payslip, :payslips]}>
        <Payslips
          id="payslips"
          select_payslip="select_payslip"
          entity={@individual.entity}
          {=@org}
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

  defp tab_classes_for(active_screen, screens) do
    if active_screen in screens do
      ~w(text-purple-500 bg-purple-300 bg-opacity-75) ++ tab_base_classes()
    else
      ~w(cursor-pointer text-gray-500 hover:bg-purple-300 hover:bg-opacity-75 hover:text-purple-500) ++
        tab_base_classes()
    end
  end

  defp tab_base_classes, do: ~w(py-2 px-4 text-sm rounded-md select-none)

  defp menu_item_classes_for(screen, active_screen) do
    ~w[block cursor-pointer text-gray-500 text-sm pl-2 py-2 rounded-md hover:bg-gray-300] ++
      ["bg-gray-300": active_screen == screen]
  end
end
