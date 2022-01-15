defmodule SigLive.AccountsPayable.Index do
  use SigLive, :surface_live_view

  alias Surface.Components.LivePatch

  alias Sig.Finance

  alias SigLive.AccountsPayable
  alias SigLive.Components.DateToggle

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       payables: [],
       payable_ids: MapSet.new(),
       financial_transactions: [],
       financial_transaction_ids: MapSet.new(),
       assigns_built_for: %{},
       org_bank_accounts:
         Finance.list_accounts_by(socket.assigns.org, where: [is_active: true, is_managed: true])
     )}
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
      overdue_at: overdue_at
    } = socket.assigns

    payables =
      Finance.list_payables_by(org,
        preload: Finance.default_payable_preloads(),
        due_date: [period_start: start_date, period_end: end_date, overdue_at: overdue_at]
      )

    assigns_built_for =
      Map.put(assigns_built_for, :accounts_payable, %{
        start_date: start_date,
        end_date: end_date
      })

    assign(socket,
      payables: payables,
      payable_ids: MapSet.new(payables, & &1.id),
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

  defp build_screen_assigns(%{assigns: %{live_action: :financial_transactions}} = socket) do
    %{org: org, assigns_built_for: assigns_built_for, start_date: start_date, end_date: end_date} =
      socket.assigns

    financial_transactions =
      Finance.list_financial_transactions_by(org,
        preload: Finance.default_financial_transaction_preloads(),
        clearing_date: [period_start: start_date, period_end: end_date]
      )

    assigns_built_for =
      Map.put(assigns_built_for, :financial_transactions, %{
        start_date: start_date,
        end_date: end_date
      })

    assign(socket,
      financial_transactions: financial_transactions,
      financial_transaction_ids: MapSet.new(financial_transactions, & &1.id),
      assigns_built_for: assigns_built_for,
      active_screen: :financial_transactions
    )
  end

  @impl true
  def handle_info({:updated_payables, _by, updated_payables}, socket) do
    %{
      payables: payables,
      payable_ids: payable_ids,
      start_date: start_date,
      end_date: end_date,
      overdue_at: overdue_at
    } = socket.assigns

    indexed_updated_payables =
      index_payables(updated_payables, payable_ids, start_date, end_date, overdue_at)

    if indexed_updated_payables == %{} do
      {:noreply, socket}
    else
      updated_payables =
        payables
        |> Map.new(&{&1.id, &1})
        |> Map.merge(indexed_updated_payables)
        |> Map.values()
        |> Enum.sort_by(& &1.description)
        |> Enum.sort_by(& &1.due_date, Date)

      {:noreply,
       assign(socket,
         payables: updated_payables,
         payable_ids: MapSet.new(updated_payables, & &1.id)
       )}
    end
  end

  @impl true
  def handle_info({:deleted_payable, deleted_payable}, socket) do
    if MapSet.member?(socket.assigns.payable_ids, deleted_payable.id) do
      %{payables: payables, payable_ids: payable_ids} = socket.assigns

      {:noreply,
       assign(socket,
         payables: Enum.reject(payables, &(&1.id == deleted_payable.id)),
         payable_ids: MapSet.delete(payable_ids, deleted_payable.id)
       )}
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

  defp index_payables(updated_payables, payable_ids, start_date, end_date, overdue_at) do
    Enum.reduce(updated_payables, %{}, fn payable, acc ->
      if Sig.Date.in_range?(payable.due_date, start_date, end_date) or
           Finance.payable_overdue?(payable, overdue_at) or
           MapSet.member?(payable_ids, payable.id) do
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
    <div class="mt-5">
      <div class="flex justify-between items-center">
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
        />
      </div>

      <div :show={@active_screen == :financial_transactions}>
        <AccountsPayable.FinancialTransactionsList
          id="financial_transactions_list"
          {=@financial_transactions}
          {=@org}
        />
      </div>
    </div>
    """
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
