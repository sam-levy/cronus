defmodule SigLive.EmployeeRegistrations.Show do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Sig.Entities
  alias Sig.HR

  alias SigLive.EmployeeRegistrations.Salaries
  alias SigLive.EmployeeRegistrations.Vouchers

  @impl true
  def mount(%{"entity_id" => entity_id, "id" => id}, _session, socket) do
    %{org: org} = socket.assigns
    individual = Entities.get_individual(org, entity_id)
    registration = HR.get_registration(individual, id)

    if connected?(socket) do
      HR.subscribe_to_registration_salaries(registration)
      HR.subscribe_to_registration_vouchers(registration)
    end

    socket =
      assign(socket,
        individual: individual,
        registration: registration,
        salaries: HR.list_salaries_by_registration(registration),
        vouchers: HR.list_vouchers_by_registration(registration)
      )

    {:ok, socket, temporary_assigns: [salaries: [], vouchers: []]}
  end

  @impl true
  def handle_info({:updated_registration_salaries, salaries}, socket) do
    {:noreply, assign(socket, salaries: salaries)}
  end

  @impl true
  def handle_info({:updated_registration_vouchers, vouchers}, socket) do
    {:noreply, assign(socket, vouchers: vouchers)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Salaries.List id="vouchers_list" {=@registration} {=@salaries}/>
      <Vouchers.List id="salaries_list" {=@registration} {=@vouchers}/>
    </div>
    """
  end
end
