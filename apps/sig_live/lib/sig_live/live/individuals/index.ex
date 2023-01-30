defmodule SigLive.Individuals.Index do
  use SigLive, :surface_live_view

  import Sig.UUID, only: [is_uuid?: 1]

  alias Surface.Components.LiveRedirect
  alias Surface.Components.Form

  alias Sig.Entities

  alias SigLive.Components.AppMenu
  alias SigLive.Components.ButtonPlus
  alias SigLive.Individuals.New

  @individuals_list_opts [
    preload: [
      :active_registrations,
      :active_registered_at_companies,
      :active_assigned_companies,
      :active_registrations_positions
    ]
  ]

  @default_filters %{
    "registered_at_company_entity_id" => "active_employees",
    "assigned_company_entity_id" => "all"
  }

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket), do: Entities.subscribe_to_individuals(org)

    socket =
      assign(socket,
        filters: @default_filters,
        default_filters: @default_filters,
        companies: Entities.list_companies(org),
        individuals: Entities.list_individuals(org, @individuals_list_opts),
        individuals_list_opts: @individuals_list_opts,
        new_individual_modal_open: false
      )

    {:ok, socket, temporary_assigns: [filtered_individuals: [:ok]]}
  end

  @impl true
  def handle_params(%{"filters" => filters}, _url, socket) do
    filtered_individuals = filter_individuals(filters, socket.assigns.individuals)

    {:noreply,
     assign(socket,
       filters: filters,
       filtered_individuals: filtered_individuals,
       filtered_individuals_count: Enum.count(filtered_individuals)
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    %{org: org, filters: filters} = socket.assigns

    {:noreply, push_patch(socket, to: build_route(socket, org, filters), replace: true)}
  end

  defp build_route(%{assigns: %{live_action: live_action}} = socket, org, filters) do
    Routes.sig_individuals_index_path(socket, live_action, org, filters: filters)
  end

  @impl true
  def handle_info("close_modals", socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_info({:updated_individuals, individuals}, socket) do
    filtered_individuals = filter_individuals(socket.assigns.filters, individuals)

    {:noreply,
     assign(socket,
       individuals: individuals,
       filtered_individuals: filtered_individuals,
       filtered_individuals_count: Enum.count(filtered_individuals)
     )}
  end

  @impl true
  def handle_event("open_new_individual_modal", _, socket) do
    {:noreply, assign(socket, :new_individual_modal_open, true)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("update_filters", params, socket) do
    org = socket.assigns.org
    filters = update_filters(params)

    {:noreply, push_patch(socket, to: build_route(socket, org, filters), replace: true)}
  end

  @impl true
  def handle_event("reset_filters", _params, socket) do
    org = socket.assigns.org

    {:noreply, push_patch(socket, to: build_route(socket, org, @default_filters), replace: true)}
  end

  defp update_filters(params) do
    params
    |> Map.filter(fn {k, _v} -> Map.has_key?(@default_filters, k) end)
    |> case do
      %{
        "registered_at_company_entity_id" => "all",
        "assigned_company_entity_id" => assigned_company_entity_id
      } = filters
      when is_uuid?(assigned_company_entity_id) ->
        Map.put(filters, "registered_at_company_entity_id", "active_employees")

      %{"registered_at_company_entity_id" => "all"} = filters ->
        Map.put(filters, "assigned_company_entity_id", "")

      filters ->
        filters
    end
  end

  defp filter_individuals(%{"registered_at_company_entity_id" => "all"}, individuals) do
    individuals
  end

  defp filter_individuals(filters, individuals) do
    individuals
    |> Enum.reduce([], fn individual, acc ->
      filters
      |> Enum.reduce_while(individual, &apply_filter/2)
      |> case do
        :reject -> acc
        _ -> [individual | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp apply_filter(
         {"registered_at_company_entity_id", "active_employees"},
         %{registered_at_companies: []}
       ) do
    {:halt, :reject}
  end

  defp apply_filter(
         {"registered_at_company_entity_id", "active_employees"},
         %{registered_at_companies: [_ | _]} = individual
       ) do
    {:cont, individual}
  end

  defp apply_filter({"registered_at_company_entity_id", entity_id}, individual) do
    case Enum.find(individual.registered_at_companies, &(&1.entity_id == entity_id)) do
      nil -> {:halt, :reject}
      _found -> {:cont, individual}
    end
  end

  defp apply_filter(
         {"assigned_company_entity_id", "all"},
         %{assigned_companies: []}
       ) do
    {:halt, :reject}
  end

  defp apply_filter(
         {"assigned_company_entity_id", "all"},
         %{assigned_companies: [_ | _]} = individual
       ) do
    {:cont, individual}
  end

  defp apply_filter({"assigned_company_entity_id", entity_id}, individual) do
    case Enum.find(individual.assigned_companies, &(&1.entity_id == entity_id)) do
      nil -> {:halt, :reject}
      _found -> {:cont, individual}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu id="app_menu" {=@org}>
        <AppMenu.Breadcrumb noslash name="RH" />
        <AppMenu.Breadcrumb name="Pessoas" />
      </AppMenu>

      <New
        :if={@new_individual_modal_open}
        id="new_individual_modal"
        close_event="close_modals"
        {=@individuals_list_opts}
        {=@org}
      />

      <table class="w-full bg-white shadow-lg mb-5">
        <thead class="top-0 sticky">
          <tr class="bg-white">
            <th colspan="1">
              <div class="flex justify-between items-center py-3 px-6">
                <ButtonPlus on_click="open_new_individual_modal" />

                <div class="text-gray-600 text-sm font-light">
                  Contagem: {@filtered_individuals_count}
                </div>

                <div class="w-35">
                  <a
                    class="btn-yellow"
                    style="padding: 0.2em 1em; font-size: 0.8em;"
                    :on-click="reset_filters"
                    :show={@filters != @default_filters}
                  >
                    Limpar filtros
                  </a>
                </div>
              </div>
            </th>

            <Form for={:filter} change="update_filters" id="filter">
              <th colspan="1" class="text-gray-500 font-medium tracking-wider">
                <div class="flex justify-start px-6">
                  <select
                    name="registered_at_company_entity_id"
                    form="filter"
                    id={@filters["registered_at_company_entity_id"]}
                    class="form-input py-1"
                  >
                    <option value="all" selected={@filters["registered_at_company_entity_id"] == "all"}>
                      Todas as Pessoas
                    </option>

                    <option
                      value="active_employees"
                      selected={@filters["registered_at_company_entity_id"] == "active_employees"}
                    >
                      Funcionários Ativos
                    </option>

                    {#for real_company <- Enum.reject(@companies, & &1.is_virtual)}
                      <option
                        value={real_company.entity_id}
                        selected={@filters["registered_at_company_entity_id"] == real_company.entity_id}
                      >
                        {real_company.trade_name}
                      </option>
                    {/for}
                  </select>
                </div>
              </th>

              <th colspan="1" class="text-gray-500 font-medium tracking-wider">
                <div class="flex justify-start px-6">
                  <select
                    name="assigned_company_entity_id"
                    form="filter"
                    id={@filters["assigned_company_entity_id"]}
                    class="form-input py-1"
                  >
                    <option value="" selected={@filters["assigned_company_entity_id"] == ""} disabled />

                    <option value="all" selected={@filters["assigned_company_entity_id"] == "all"}>
                      Todas as Empresas
                    </option>

                    {#for company <- Enum.sort_by(@companies, & &1.is_virtual)}
                      <option
                        value={company.entity_id}
                        selected={@filters["assigned_company_entity_id"] == company.entity_id}
                      >
                        {company.trade_name}
                      </option>
                    {/for}
                  </select>
                </div>
              </th>
            </Form>
          </tr>

          <tr class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Nome</th>
            <th class="py-3 px-6 text-left">Registro</th>
            <th class="py-3 px-6 text-left">Designação</th>
            <th class="py-3 px-6 text-left">Cargo</th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for individual <- @filtered_individuals}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                <LiveRedirect
                  to={Routes.sig_individuals_show_path(@socket, :show, @org, individual.entity)}
                  class="hover:underline"
                >
                  {individual.name}
                </LiveRedirect>
              </td>

              <td class="py-3 px-6 text-left">
                <div :if={is_non_empty_list(individual.registrations)}>
                  <LiveRedirect
                    to={Routes.sig_employee_registrations_show_path(
                      @socket,
                      :registration_summary,
                      @org,
                      List.first(individual.registrations)
                    )}
                    class="hover:underline"
                  >
                    <span>{first_item_attr(individual.registered_at_companies, :trade_name)}</span>
                  </LiveRedirect>

                  <span :if={tail_count(individual.registered_at_companies) > 0}>
                    + {tail_count(individual.registered_at_companies)}</span>
                </div>
              </td>

              <td class="py-3 px-6 text-left">
                <div :if={is_non_empty_list(individual.assigned_companies)}>
                  <span>{first_item_attr(individual.assigned_companies, :trade_name)}</span>

                  <span :if={tail_count(individual.assigned_companies) > 0}>
                    + {tail_count(individual.assigned_companies)}</span>
                </div>
              </td>

              <td class="py-3 px-6 text-left">
                <span>{first_item_attr(individual.positions, :name)}</span>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  defp closed_state do
    [new_individual_modal_open: false]
  end

  defp is_non_empty_list([]), do: false
  defp is_non_empty_list([_ | _]), do: true

  defp first_item_attr([], _attr), do: ""
  defp first_item_attr([item], attr), do: Map.get(item, attr)
  defp first_item_attr([item | _], attr), do: Map.get(item, attr)

  defp tail_count([]), do: 0
  defp tail_count([_]), do: 0
  defp tail_count([_ | tail]), do: Enum.count(tail)
end
