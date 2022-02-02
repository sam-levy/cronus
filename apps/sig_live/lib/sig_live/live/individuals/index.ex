defmodule SigLive.Individuals.Index do
  use SigLive, :surface_live_view

  alias Surface.Components.LiveRedirect
  alias Surface.Components.Form

  alias Sig.Entities

  alias SigLive.Components.AppMenu
  alias SigLive.Components.ButtonPlus
  alias SigLive.Individuals.New

  @individuals_list_opts [preload: :active_registered_at_companies]

  @filters %{"registered_at_company_entity_id" => "all"}

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket), do: Entities.subscribe_to_individuals(org)

    socket =
      assign(socket,
        filters: @filters,
        companies: Entities.list_companies(org, filter: [is_virtual: false]),
        individuals: Entities.list_individuals(org, @individuals_list_opts),
        individuals_list_opts: @individuals_list_opts,
        new_individual_modal_open: false
      )

    {:ok, socket, temporary_assigns: [filtered_individuals: [:ok]]}
  end

  @impl true
  def handle_params(%{"filters" => filters}, _url, socket) do
    filtered_individuals = filter_individuals(filters, socket.assigns.individuals)

    {:noreply, assign(socket, filters: filters, filtered_individuals: filtered_individuals)}
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
     assign(socket, individuals: individuals, filtered_individuals: filtered_individuals)}
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
  def handle_event("filter_individuals", params, socket) do
    %{org: org, filters: filters} = socket.assigns

    filters = update_filters(filters, params)

    {:noreply, push_patch(socket, to: build_route(socket, org, filters), replace: true)}
  end

  defp update_filters(filters, params) do
    Enum.reduce(filters, filters, fn {filter_k, _old_value}, acc ->
      case Map.get(params, filter_k) do
        nil -> acc
        new_value -> Map.put(acc, filter_k, new_value)
      end
    end)
  end

  defp filter_individuals(filters, individuals) do
    Enum.reduce(individuals, [], fn individual, acc ->
      filters
      |> Enum.reduce_while(individual, &apply_filter/2)
      |> case do
        :reject -> acc
        _ -> [individual | acc]
      end
    end)
  end

  defp apply_filter({"registered_at_company_entity_id", "all"}, individual) do
    {:cont, individual}
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

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 sticky">
          <tr class="bg-white">
            <th colspan="3">
              <div class="flex justify-between items-center py-3 px-6 text-gray-500 font-medium tracking-wider">
                <Form for={:filter} change="filter_individuals">
                  <select name="registered_at_company_entity_id" class="form-input py-1">
                    <option value="all" selected={@filters["registered_at_company_entity_id"] == "all"}>
                      Todas as Pessoas
                    </option>

                    <option
                      value="active_employees"
                      selected={@filters["registered_at_company_entity_id"] == "active_employees"}
                    >
                      Funcionários Ativos
                    </option>

                    {#for company <- @companies}
                      <option
                        value={company.entity_id}
                        selected={company.entity_id == @filters["registered_at_company_entity_id"]}
                      >
                        {company.trade_name}
                      </option>
                    {/for}
                  </select>
                </Form>

                <ButtonPlus on_click="open_new_individual_modal" />
              </div>
            </th>
          </tr>

          <tr class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Nome</th>
            <th class="py-3 px-6 text-left">CPF</th>
            <th class="py-3 px-6 text-left">Registro Ativo</th>
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

              <td class="py-3 px-6 text-left select-all">
                <span>{format_cpf(individual.cpf)}</span>
              </td>

              <td class="py-3 px-6 text-left">
                <span>{handle_company_names(individual.registered_at_companies)}</span>
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

  defp handle_company_names([]), do: ""

  defp handle_company_names([company]), do: company.trade_name

  defp handle_company_names([company | others]) do
    "#{company.trade_name} + #{Enum.count(others)}"
  end
end
