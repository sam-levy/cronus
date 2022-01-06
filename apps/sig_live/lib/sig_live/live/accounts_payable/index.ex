defmodule SigLive.AccountsPayable.Index do
  use SigLive, :surface_live_view

  alias Sig.Finance

  alias SigLive.AccountsPayable
  alias SigLive.Components.DateToggle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_due_date_period()

    {:ok, socket}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_event(
        "assign_due_date",
        %{"toggle_date" => %{"start_date" => start_date, "end_date" => end_date}},
        socket
      ) do
    with {:ok, start_date} <- Date.from_iso8601(start_date),
         {:ok, end_date} <- Date.from_iso8601(end_date) do
      case Date.compare(start_date, end_date) do
        :gt -> {:noreply, assign_due_date_period(socket, start_date, start_date)}
        _ -> {:noreply, assign_due_date_period(socket, start_date, end_date)}
      end
    else
      _ ->
        {:noreply, assign_due_date_period(socket)}
    end
  end

  @impl true
  def handle_event("next_day", _params, socket) do
    next_day = Date.add(socket.assigns.due_date_start, 1)

    {:noreply, assign_due_date_period(socket, next_day, next_day)}
  end

  @impl true
  def handle_event("previous_day", _params, socket) do
    previous_day = Date.add(socket.assigns.due_date_start, -1)

    {:noreply, assign_due_date_period(socket, previous_day, previous_day)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="mt-5">
      <DateToggle
        start_date={@due_date_start}
        end_date={@due_date_end}
        handle_period="assign_due_date"
        next="next_day"
        previous="previous_day"
      />

      <AccountsPayable.List
        id="accounts_payable_list"
        {=@payables}
        {=@org}
      />
    </div>
    """
  end

  defp assign_due_date_period(socket) do
    assign_due_date_period(socket, Date.utc_today(), Date.utc_today())
  end

  defp assign_due_date_period(socket, start_date, end_date) do
    %{org: org} = socket.assigns

    payables =
      Finance.list_payables(org,
        authorized_by: true,
        preload: [:payslip, :employee, :employee_registration_company],
        due_date: [period_start: start_date, period_end: end_date]
      )

    assign(socket,
      payables: payables,
      due_date_start: start_date,
      due_date_end: end_date
    )
  end
end
