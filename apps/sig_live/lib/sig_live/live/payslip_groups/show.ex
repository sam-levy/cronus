defmodule SigLive.PayslipGroups.Show do
  use SigLive, :surface_live_view
  use SigLive.PayslipsState

  alias Sig.HR
  alias Sig.Entities

  alias SigLive.Payslips.ShowWithPayables
  alias SigLive.PayslipGroups.Payslips.List, as: PayslipsList

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    %{org: org} = socket.assigns

    case HR.fetch_group(org, id) do
      {:error, :not_found} ->
        {:ok,
         push_redirect(socket,
           to: Routes.sig_payslip_groups_list_path(socket, :payslip_groups, org)
         )}

      {:ok, group} ->
        payslips = HR.list_payslips_by(group, preload_registration: true)
        selected_payslip = List.first(payslips)

        if connected?(socket) do
          HR.subscribe_to_groups(group)
          HR.subscribe_to_payslips(group)

          if selected_payslip, do: subscribe_to_payslip_subscriptions(selected_payslip)
        end

        socket =
          socket
          |> assign(
            group: group,
            payslips: payslips,
            companies: Entities.list_companies(org, filter: [is_virtual: false]),
            selected_company_entity_id: nil,
            filtered_payslips: [],
            payslips_filters: %{company_entity_id: "", individual_entity_name: ""}
          )
          |> assign_selected_payslip(selected_payslip)
          |> handle_apply_payslip_filters()

        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:deleted_payslip_group, group}, socket) do
    if group.id == socket.assigns.group.id do
      {:noreply,
       push_redirect(socket,
         to: Routes.sig_payslip_groups_list_path(socket, :payslip_groups, socket.assigns.org)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_payslip", %{"payslip_id" => id}, socket) do
    payslip = HR.get_payslip(socket.assigns.group, id, preload_registration: true)

    unsubscribe_from_payslip_subscriptions(socket.assigns.selected_payslip)
    subscribe_to_payslip_subscriptions(payslip)

    {:noreply, assign_selected_payslip(socket, payslip)}
  end

  @impl true
  def handle_event("filter_payslips", filters, socket) do
    {:noreply,
     socket
     |> set_filters(filters)
     |> handle_apply_payslip_filters()}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="mt-4 text-lg text-gray-500 font-medium tracking-wider mr-4">
        Holerites {format_month(@group.date)}

        <span class="text-gray-400 italic font-extralight">
          {capitalize_type(@group.type)}
        </span>
      </div>

      <div class="flex mt-4 divide-x divide-gray-400 divide-opacity-50">
        <div class="w-3/4 pr-5">
          <ShowWithPayables
            hide_payslip_date
            id="payslip_show_with_payables"
            payslip={@selected_payslip}
            payslip_items={@selected_payslip_items}
            payslip_payables={@selected_payslip_payables}
            registration={@selected_payslip.registration}
            entity={@selected_payslip.registration.individual.entity}
            {=@org}
            {=@current_user}
          />
        </div>

        <div class="w-1/4 pl-5">
          <PayslipsList
            id="payslip_list"
            payslips={@filtered_payslips}
            selected_payslip_id={@selected_payslip && @selected_payslip.id}
            select_payslip="select_payslip"
            filter_payslips="filter_payslips"
            {=@companies}
            {=@payslips_filters}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl SigLive.PayslipsState
  def handle_updated_payslip(updated_payslip, socket) do
    %{group: group, payslips: payslips, selected_payslip: selected_payslip} = socket.assigns

    if updated_payslip.group_id == group.id do
      payslips =
        [updated_payslip | payslips]
        |> Enum.uniq_by(& &1.id)
        |> sort_payslips()

      if selected_payslip != nil and selected_payslip.id == updated_payslip.id do
        {:noreply,
         socket
         |> assign(payslips: payslips, selected_payslip: updated_payslip)
         |> handle_apply_payslip_filters()}
      else
        {:noreply,
         socket
         |> assign(payslips: payslips)
         |> handle_apply_payslip_filters()}
      end
    else
      send(self(), {:deleted_payslip, updated_payslip})

      {:noreply, socket}
    end
  end

  @impl SigLive.PayslipsState
  def handle_empty_payslips(socket) do
    %{org: org} = socket.assigns

    push_redirect(socket, to: Routes.sig_payslip_groups_list_path(socket, :payslip_groups, org))
  end

  @impl SigLive.PayslipsState
  def sort_payslips(payslips) do
    Enum.sort_by(
      payslips,
      &{&1.registration.registered_at.trade_name, &1.registration.individual.name}
    )
  end

  @impl SigLive.PayslipsState
  def handle_apply_payslip_filters(socket) do
    socket
    |> filter_by_company_entity_id()
    |> filter_by_individual_entity_name()
  end

  defp set_filters(socket, filters) do
    assign(socket,
      payslips_filters: %{
        company_entity_id: filters["company_entity_id"],
        individual_entity_name: filters["individual_entity_name"]
      }
    )
  end

  defp filter_by_company_entity_id(socket) do
    %{payslips: payslips, payslips_filters: %{company_entity_id: company_entity_id}} =
      socket.assigns

    if company_entity_id == "" do
      assign(socket, filtered_payslips: payslips)
    else
      filtered_payslips =
        Enum.filter(payslips, &(&1.registration.registered_at_id == company_entity_id))

      assign(socket, filtered_payslips: filtered_payslips)
    end
  end

  defp filter_by_individual_entity_name(socket) do
    %{
      filtered_payslips: filtered_payslips,
      payslips_filters: %{individual_entity_name: individual_entity_name}
    } = socket.assigns

    with true <- String.length(individual_entity_name) > 2,
         {:ok, regex} <- Regex.compile(individual_entity_name, "i") do
      filtered_payslips =
        Enum.filter(filtered_payslips, &String.match?(&1.registration.individual.name, regex))

      assign(socket, filtered_payslips: filtered_payslips)
    else
      _ -> assign(socket, filtered_payslips: filtered_payslips)
    end
  end
end
