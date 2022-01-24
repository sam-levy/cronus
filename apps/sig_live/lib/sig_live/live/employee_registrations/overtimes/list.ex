defmodule SigLive.EmployeeRegistrations.Overtimes.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Overtimes.Form
  alias SigLive.EmployeeRegistrations.Overtimes.AssignPayslipForm

  prop registration, :struct, required: true
  prop overtimes, :list, required: true

  data delete_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()
  data assign_payslip_form_state, :atom, default: :closed, values!: AssignPayslipForm.states()
  data form_state, :atom, default: :closed, values!: Form.states()
  data overtime_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def update(%{overtimes: overtimes} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(hours_sum: handle_hours_sum(overtimes))

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("open_new_overtime_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_overtime_form", %{"overtime_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, overtime_id: id)}
  end

  @impl true
  def handle_event("open_assign_payslip_form", %{"overtime_id" => id}, socket) do
    {:noreply, assign(socket, assign_payslip_form_state: :open, overtime_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"overtime_id" => id}, socket) do
    {:noreply, assign(socket, delete_confirmation_dialog_state: :open, overtime_id: id)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("drop_payslip", %{"overtime_id" => id}, socket) do
    %{registration: registration} = socket.assigns

    with {:ok, overtime} <- HR.fetch_overtime(registration, id),
         {:ok, _overtime} <- HR.drop_overtime_payslip(overtime) do
      HR.broadcast_registration_overtimes(registration)
      flash_info("Holerite destribuído")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, changeset} when is_struct(changeset) ->
        message = Sig.Changeset.errors_to_string(changeset)

        {:noreply, assign(socket, :message, message)}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :message, message)}
    end
  end

  @impl true
  def handle_event("delete_overtime", _params, socket) do
    %{registration: registration, overtime_id: id} = socket.assigns

    with {:ok, overtime} <- HR.fetch_overtime(registration, id),
         {:ok, _overtime} <- HR.delete_overtime(overtime) do
      HR.broadcast_registration_overtimes(registration)
      flash_info("Horas extras removidas")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, changeset} when is_struct(changeset) ->
        message = Sig.Changeset.errors_to_string(changeset)

        {:noreply, assign(socket, :message, message)}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :message, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_overtime"
        dialog_title="Confirmar Remoção"
        confirmation_msg="Deseja realmente remover as horas extras?"
        action_btn_msg="Remover"
        error_message={@message}
      />

      <Form
        :if={@form_state != :closed}
        id="overtime_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@registration}
        {=@overtime_id}
      />

      <AssignPayslipForm
        :if={@assign_payslip_form_state != :closed}
        id="assign_payslip_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        form_state={@assign_payslip_form_state}
        {=@registration}
        {=@overtime_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Horas Extras
                </span>

                <ButtonPlus on_click="open_new_overtime_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@overtimes != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Data</th>
            <th class="py-3 px-6 text-left">Horas</th>
            <th class="py-3 px-6 text-left">Holerite</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for overtime <- @overtimes}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {format_month(overtime.date)}
              </td>

              <td class="py-3 pl-6 text-left">
                {overtime.hours_amount}
              </td>

              <td class="py-3 pl-6 text-left">
                {overtime.payslip && format_month(overtime.payslip.start_date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :if={overtime.payslip_id == nil}
                    :on-click="open_assign_payslip_form"
                    phx-value-overtime_id={overtime.id}
                    class="dropdown-item"
                  >
                    Atribuir Holerite
                  </a>

                  <a
                    :if={overtime.payslip_id != nil}
                    :on-click="drop_payslip"
                    phx-value-overtime_id={overtime.id}
                    class="dropdown-item"
                  >
                    Desatribuir Holerite
                  </a>

                  <a
                    :if={overtime.payslip_id == nil}
                    :on-click="open_edit_overtime_form"
                    phx-value-overtime_id={overtime.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :if={overtime.payslip_id == nil}
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-overtime_id={overtime.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr :if={@overtimes != []} class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left">Horas extras em aberto</td>
            <td class="py-2 px-6 text-left">{@hours_sum}</td>
            <td colspan="2"></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      overtime_id: nil,
      message: nil,
      form_state: :closed,
      assign_payslip_form_state: :closed,
      delete_confirmation_dialog_state: :closed
    ]
  end

  defp handle_hours_sum(overtimes) do
    Enum.reduce(overtimes, Sig.Hour.new(), fn
      %{payslip_id: nil, hours_amount: amount}, acc -> Sig.Hour.add(acc, amount)
      _overtime, acc -> acc
    end)
  end
end
