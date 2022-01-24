defmodule SigLive.AccountsPayable.Index do
  use SigLive, :surface_live_view

  alias Surface.Components.LivePatch

  alias Sig.Entities
  alias Sig.Finance

  alias SigLive.Components.AppMenu
  alias SigLive.AccountsPayable
  alias SigLive.Components.DateToggle

  @filters %{company_entity_id: "all"}

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    socket =
      assign(socket,
        payables: [],
        indexed_payables: %{},
        payables_amount_sum: Money.new(0),
        financial_transactions: [],
        financial_transaction_ids: MapSet.new(),
        assigns_built_for: %{},
        filters: @filters,
        companies: Entities.list_companies(org, filter: [is_virtual: false]),
        org_bank_accounts:
          Finance.list_accounts_by(org, where: [is_active: true, is_managed: true]),
        selected_summary_description: AccountsPayable.Summary.default_description()
      )

    {:ok, socket, temporary_assigns: [payables: []]}
  end

  @impl true
  def handle_params(%{"start_date" => start_date, "end_date" => end_date}, _url, socket) do
    with {:ok, start_date} <- Date.from_iso8601(start_date),
         {:ok, end_date} <- Date.from_iso8601(end_date) do
      case Date.compare(start_date, end_date) do
        :gt -> {:noreply, route_with_period(socket, start_date, start_date)}
        _lt_or_eq -> {:noreply, handle_assigns(socket, start_date, end_date)}
      end
    else
      {:error, _} ->
        today = Date.utc_today()

        {:noreply, route_with_period(socket, today, today)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    today = Date.utc_today()

    {:noreply, route_with_period(socket, today, today)}
  end

  defp route_with_period(socket, start_date, end_date) do
    %{org: org, live_action: live_action} = socket.assigns

    push_patch(socket,
      to: build_route(socket, live_action, org, start_date, end_date),
      replace: true
    )
  end

  defp build_route(socket, live_action, org, start_date, end_date) do
    Routes.sig_accounts_payable_index_path(socket, live_action, org,
      start_date: to_iso8601(start_date),
      end_date: to_iso8601(end_date)
    )
  end

  defp to_iso8601(%Date{} = date), do: Date.to_iso8601(date)
  defp to_iso8601(date) when is_binary(date), do: date

  defp handle_assigns(socket, start_date, end_date) do
    socket
    |> assign(start_date: start_date, end_date: end_date, overdue_at: Date.utc_today())
    |> handle_subscriptions()
    |> build_screen_assigns()
  end

  defp handle_subscriptions(
         %{assigns: %{live_action: :accounts_payable, assigns_built_for: %{accounts_payable: _}}} =
           socket
       ) do
    socket
  end

  defp handle_subscriptions(%{assigns: %{live_action: :accounts_payable}} = socket) do
    if connected?(socket), do: Finance.subscribe_to_payables(socket.assigns.org)

    socket
  end

  defp handle_subscriptions(
         %{
           assigns: %{
             live_action: :financial_transactions,
             assigns_built_for: %{financial_transactions: _}
           }
         } = socket
       ) do
    socket
  end

  defp handle_subscriptions(%{assigns: %{live_action: :financial_transactions}} = socket) do
    if connected?(socket), do: Finance.subscribe_to_financial_transactions(socket.assigns.org)

    socket
  end

  defp handle_subscriptions(
         %{assigns: %{live_action: :summary, assigns_built_for: %{financial_transactions: _}}} =
           socket
       ) do
    socket
  end

  defp handle_subscriptions(
         %{assigns: %{live_action: :summary, assigns_built_for: %{summary: _}}} = socket
       ) do
    socket
  end

  defp handle_subscriptions(%{assigns: %{live_action: :summary}} = socket) do
    if connected?(socket), do: Finance.subscribe_to_financial_transactions(socket.assigns.org)

    socket
  end

  defp build_screen_assigns(
         %{
           assigns: %{
             live_action: :accounts_payable,
             assigns_built_for: %{accounts_payable: %{start_date: start_date, end_date: end_date}},
             start_date: start_date,
             end_date: end_date
           }
         } = socket
       ) do
    assign(socket, active_screen: :accounts_payable)
  end

  defp build_screen_assigns(%{assigns: %{live_action: :accounts_payable}} = socket) do
    %{
      org: org,
      assigns_built_for: assigns_built_for,
      start_date: start_date,
      end_date: end_date,
      overdue_at: overdue_at,
      filters: filters
    } = socket.assigns

    indexed_payables =
      org
      |> Finance.list_payables_by(
        preload: Finance.default_payable_preloads(),
        due_date: [period_start: start_date, period_end: end_date, overdue_at: overdue_at]
      )
      |> Map.new(&{&1.id, &1})

    assigns_built_for =
      Map.put(assigns_built_for, :accounts_payable, %{
        start_date: start_date,
        end_date: end_date
      })

    socket
    |> assign_payables(indexed_payables, filters)
    |> assign(
      indexed_payables: indexed_payables,
      assigns_built_for: assigns_built_for,
      active_screen: :accounts_payable
    )
  end

  defp build_screen_assigns(
         %{
           assigns: %{
             live_action: :financial_transactions,
             assigns_built_for: %{
               financial_transactions: %{start_date: start_date, end_date: end_date}
             },
             start_date: start_date,
             end_date: end_date
           }
         } = socket
       ) do
    assign(socket, active_screen: :financial_transactions)
  end

  defp build_screen_assigns(
         %{
           assigns: %{
             live_action: :financial_transactions,
             assigns_built_for:
               %{
                 summary: %{start_date: start_date, end_date: end_date}
               } = assigns_built_for,
             start_date: start_date,
             end_date: end_date
           }
         } = socket
       ) do
    assigns_built_for =
      Map.put(assigns_built_for, :financial_transactions, %{
        start_date: start_date,
        end_date: end_date
      })

    assign(socket, assigns_built_for: assigns_built_for, active_screen: :financial_transactions)
  end

  defp build_screen_assigns(%{assigns: %{live_action: :financial_transactions}} = socket) do
    %{org: org, assigns_built_for: assigns_built_for, start_date: start_date, end_date: end_date} =
      socket.assigns

    assigns_built_for =
      Map.put(assigns_built_for, :financial_transactions, %{
        start_date: start_date,
        end_date: end_date
      })

    financial_transactions = fetch_financial_transactions(org, start_date, end_date)

    assign(socket,
      financial_transactions: financial_transactions,
      financial_transaction_ids: MapSet.new(financial_transactions, & &1.id),
      assigns_built_for: assigns_built_for,
      active_screen: :financial_transactions
    )
  end

  defp build_screen_assigns(
         %{
           assigns: %{
             live_action: :summary,
             assigns_built_for: %{
               summary: %{start_date: start_date, end_date: end_date}
             },
             start_date: start_date,
             end_date: end_date
           }
         } = socket
       ) do
    assign(socket, active_screen: :summary)
  end

  defp build_screen_assigns(
         %{
           assigns: %{
             live_action: :summary,
             assigns_built_for:
               %{
                 financial_transactions: %{start_date: start_date, end_date: end_date}
               } = assigns_built_for,
             start_date: start_date,
             end_date: end_date
           }
         } = socket
       ) do
    assigns_built_for =
      Map.put(assigns_built_for, :summary, %{
        start_date: start_date,
        end_date: end_date
      })

    assign(socket, assigns_built_for: assigns_built_for, active_screen: :summary)
  end

  defp build_screen_assigns(%{assigns: %{live_action: :summary}} = socket) do
    %{org: org, assigns_built_for: assigns_built_for, start_date: start_date, end_date: end_date} =
      socket.assigns

    assigns_built_for =
      Map.put(assigns_built_for, :summary, %{
        start_date: start_date,
        end_date: end_date
      })

    financial_transactions = fetch_financial_transactions(org, start_date, end_date)

    assign(socket,
      financial_transactions: financial_transactions,
      financial_transaction_ids: MapSet.new(financial_transactions, & &1.id),
      assigns_built_for: assigns_built_for,
      active_screen: :summary
    )
  end

  defp fetch_financial_transactions(org, start_date, end_date) do
    Finance.list_financial_transactions_by(org,
      filter_by: [clearing_date_period: [period_start: start_date, period_end: end_date]],
      preload: Finance.default_financial_transaction_preloads()
    )
  end

  @impl true
  def handle_info({:updated_payables, _by, incoming_payables}, socket) do
    %{
      indexed_payables: indexed_payables,
      start_date: start_date,
      end_date: end_date,
      overdue_at: overdue_at,
      filters: filters
    } = socket.assigns

    indexed_incoming_payables =
      index_incoming_payables(
        incoming_payables,
        indexed_payables,
        start_date,
        end_date,
        overdue_at
      )

    if indexed_incoming_payables == %{} do
      {:noreply, socket}
    else
      updated_indexed_payables = Map.merge(indexed_payables, indexed_incoming_payables)

      {:noreply,
       socket
       |> assign(indexed_payables: updated_indexed_payables)
       |> assign_payables(updated_indexed_payables, filters)}
    end
  end

  @impl true
  def handle_info({:deleted_payable, deleted_payable}, socket) do
    %{indexed_payables: indexed_payables, filters: filters} = socket.assigns

    if Map.get(indexed_payables, deleted_payable.id, false) do
      updated_indexed_payables = Map.delete(indexed_payables, deleted_payable.id)

      {:noreply,
       socket
       |> assign(indexed_payables: updated_indexed_payables)
       |> assign_payables(updated_indexed_payables, filters)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_financial_transaction, ft}, socket) do
    %{start_date: start_date, end_date: end_date} = socket.assigns

    if eligible_financial_transaction?(ft, start_date, end_date) do
      updated_fts = [ft | socket.assigns.financial_transactions]

      {:noreply,
       assign(socket,
         financial_transactions: updated_fts,
         financial_transaction_ids: MapSet.new(updated_fts, & &1.id)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:updated_financial_transaction, updated_ft}, socket) do
    %{financial_transaction_ids: ft_ids, start_date: start_date, end_date: end_date} =
      socket.assigns

    if eligible_financial_transaction?(updated_ft, start_date, end_date) or
         MapSet.member?(ft_ids, updated_ft.id) do
      updated_ft_id = updated_ft.id

      updated_fts =
        Enum.map(socket.assigns.financial_transactions, fn
          %{id: ^updated_ft_id} -> updated_ft
          ft -> ft
        end)

      {:noreply,
       assign(socket,
         financial_transactions: updated_fts,
         financial_transaction_ids: MapSet.new(updated_fts, & &1.id)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:deleted_financial_transaction, deleted_ft}, socket) do
    if MapSet.member?(socket.assigns.financial_transaction_ids, deleted_ft.id) do
      %{financial_transactions: financial_transactions, financial_transaction_ids: ft_ids} =
        socket.assigns

      {:noreply,
       assign(socket,
         financial_transactions: Enum.reject(financial_transactions, &(&1.id == deleted_ft.id)),
         financial_transaction_ids: MapSet.delete(ft_ids, deleted_ft.id)
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:filter_company, company_entity_id}, socket) do
    %{filters: filters, indexed_payables: indexed_payables} = socket.assigns

    updated_filters = %{filters | company_entity_id: company_entity_id}

    {:noreply,
     socket
     |> assign(filters: updated_filters)
     |> assign_payables(indexed_payables, updated_filters)}
  end

  defp assign_payables(socket, indexed_payables, filters) do
    acc = %{payables: [], payables_amount_sum: Money.new(0)}

    %{payables: payables, payables_amount_sum: payables_amount_sum} =
      Enum.reduce(indexed_payables, acc, fn {_payable_id, payable}, acc ->
        filters
        |> Enum.reduce_while(payable, &apply_filter/2)
        |> case do
          :reject ->
            acc

          _ ->
            acc
            |> Sig.Map.flat_put(:payables, payable)
            |> Map.put(:payables_amount_sum, Money.add(acc.payables_amount_sum, payable.amount))
        end
      end)

    payables =
      payables
      |> Enum.sort_by(& &1.inserted_at, DateTime)
      |> Enum.sort_by(& &1.due_date, Date)

    assign(socket, payables: payables, payables_amount_sum: payables_amount_sum)
  end

  defp apply_filter({:company_entity_id, "all"}, payable), do: {:cont, payable}

  defp apply_filter(
         {:company_entity_id, id},
         %{employee_registration_company: %{entity_id: id}} = payable
       ) do
    {:cont, payable}
  end

  defp apply_filter(_filter, _payable), do: {:halt, :reject}

  defp index_incoming_payables(
         incoming_payables,
         indexed_payables,
         start_date,
         end_date,
         overdue_at
       ) do
    Enum.reduce(incoming_payables, %{}, fn payable, acc ->
      if Sig.Date.in_range?(payable.due_date, start_date, end_date) or
           Finance.payable_overdue?(payable, overdue_at) or
           Map.get(indexed_payables, payable.id, false) do
        Map.put(acc, payable.id, payable)
      else
        acc
      end
    end)
  end

  defp eligible_financial_transaction?(%{clearing_date: nil} = ft, start_date, end_date) do
    Sig.Date.in_range?(ft.placement_date, start_date, end_date)
  end

  defp eligible_financial_transaction?(ft, start_date, end_date) do
    Sig.Date.in_range?(ft.clearing_date, start_date, end_date)
  end

  @impl true
  def handle_event(
        "assign_due_date",
        %{"toggle_date" => %{"start_date" => start_date, "end_date" => end_date}},
        socket
      ) do
    {:noreply, route_with_period(socket, start_date, end_date)}
  end

  @impl true
  def handle_event("next_day", _params, socket) do
    next_day = Date.add(socket.assigns.start_date, 1)

    {:noreply, route_with_period(socket, next_day, next_day)}
  end

  @impl true
  def handle_event("go_to_today", _params, socket) do
    today = Date.utc_today()

    {:noreply, route_with_period(socket, today, today)}
  end

  @impl true
  def handle_event("previous_day", _params, socket) do
    previous_day = Date.add(socket.assigns.end_date, -1)

    {:noreply, route_with_period(socket, previous_day, previous_day)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>

      <div class="flex justify-between items-center">
        <AppMenu>
          <AppMenu.Breadcrumb noslash name="Financeiro" />
        </AppMenu>

        <DateToggle
          start_date={@start_date}
          end_date={@end_date}
          custom_date_event="go_to_today"
          custom_date_name="Hoje"
          handle_period="assign_due_date"
          next="next_day"
          previous="previous_day"
        />

        <div class="flex flex-row justify-end space-x-4">
          <LivePatch
            to={build_route(@socket, :accounts_payable, @org, @start_date, @end_date)}
            class={tab_classes_for(:accounts_payable, @active_screen)}
          >
            Contas a Pagar
          </LivePatch>

          <LivePatch
            to={build_route(@socket, :financial_transactions, @org, @start_date, @end_date)}
            class={tab_classes_for(:financial_transactions, @active_screen)}
          >
            Transações
          </LivePatch>

          <LivePatch
            to={build_route(@socket, :summary, @org, @start_date, @end_date)}
            class={tab_classes_for(:summary, @active_screen)}
          >
            Resumo
          </LivePatch>
        </div>
      </div>

      <div :show={@active_screen == :accounts_payable}>
        <AccountsPayable.List
          id="accounts_payable_list"
          {=@org}
          {=@current_user}
          {=@org_bank_accounts}
          {=@overdue_at}
          {=@payables}
          {=@payables_amount_sum}
          {=@companies}
          {=@filters}
        />
      </div>

      <div :show={@active_screen == :financial_transactions}>
        <AccountsPayable.FinancialTransactionsList
          id="financial_transactions_list"
          {=@financial_transactions}
          {=@org}
        />
      </div>

      <div :if={@active_screen == :summary}>
        <AccountsPayable.Summary
          id="financial_transactions_summary"
          selected_description={@selected_summary_description}
          select_description="select_summary_description"
          {=@org}
          {=@org_bank_accounts}
          {=@financial_transactions}
          {=@financial_transaction_ids}
        />
      </div>
    </div>
    """
  end

  # TODO: Remove handler and state once summary is removed
  @impl true
  def handle_info({:selected_summary_description, description}, socket) do
    {:noreply, assign(socket, selected_summary_description: description)}
  end

  defp tab_classes_for(screen, screen) do
    ~w(text-purple-500 bg-purple-300 bg-opacity-75) ++ tab_base_classes()
  end

  defp tab_classes_for(_screen, _active_screen) do
    ~w(cursor-pointer text-gray-500 hover:bg-purple-300 hover:bg-opacity-75 hover:text-purple-500) ++
      tab_base_classes()
  end

  defp tab_base_classes, do: ~w(py-2 px-4 text-sm rounded-md select-none)
end
