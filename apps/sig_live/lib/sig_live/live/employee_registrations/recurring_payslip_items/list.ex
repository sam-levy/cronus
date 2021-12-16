defmodule SigLive.EmployeeRegistrations.RecurringPayslipItems.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.OutsideItemForm
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.PayslipItemForm
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.PayslipItemModelForm
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.MonthToggle
  alias SigLive.EmployeeRegistrations.RecurringPayslipItems.CreateFromPayslipTemplateForm

  prop registration, :struct, required: true
  prop recurring_payslip_items, :list, required: true

  data payslip_item_form_state, :atom, default: :closed, values!: PayslipItemForm.states()
  data payslip_item_model_form_state, :atom, default: :closed, values!: PayslipItemModelForm.states()
  data payslip_template_form_state, :atom, default: :closed, values!: CreateFromPayslipTemplateForm.states()
  data outside_item_form_state, :atom, default: :closed, values!: OutsideItemForm.states()
  data delete_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()

  data item_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def update(%{recurring_payslip_items: items} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(target_date: Date.utc_today() |> Date.beginning_of_month())
      |> assign_items(items)
      |> assign_totals()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("previous_month", _, socket) do
    %{target_date: date} = socket.assigns
    target_date = date |> Date.add(-1) |> Date.beginning_of_month()

    update_items(socket, target_date)
  end

  @impl true
  def handle_event("next_month", _, socket) do
    %{target_date: date} = socket.assigns
    target_date = date |> Date.end_of_month() |> Date.add(1)

    update_items(socket, target_date)
  end

  @impl true
  def handle_event("open_new_payslip_item_form", _, socket) do
    {:noreply, assign(socket, payslip_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_new_payslip_item_model_form", _, socket) do
    {:noreply, assign(socket, payslip_item_model_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_new_payslip_items_from_payslip_template_form", _, socket) do
    {:noreply, assign(socket, payslip_template_form_state: :open)}
  end

  @impl true
  def handle_event("open_new_outside_item_form", _, socket) do
    {:noreply, assign(socket, outside_item_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_payslip_item_delete_confirmation_dialog", %{"item_id" => id}, socket) do
    {:noreply, assign(socket, delete_confirmation_dialog_state: :open, item_id: id)}
  end

  @impl true
  def handle_event("delete_recurring_payslip_item", _, socket) do
    %{registration: registration, item_id: item_id} = socket.assigns

    case HR.delete_recurring_payslip_item(registration, item_id) do
      {:ok, _item} ->
        HR.broadcast_registration_recurring_payslip_items(registration)
        send(self(), {:flash, :info, "Item removido"})

        {:noreply, assign(socket, closed_state())}

      {:error, message} ->
        send(self(), {:flash, :info, "Falha ao remover o item"})

      {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_confirmation_dialog_state != :closed}
        error_message={@message}
        close_event="close_modals"
        action_event="delete_recurring_payslip_item"
        dialog_title="Confirmar Remoção"
        confirmation_msg="Deseja realmente remover o item?"
        action_btn_msg="Remover"
      />

      <CreateFromPayslipTemplateForm
        :if={@payslip_template_form_state != :closed}
        id="payslip_template_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <PayslipItemForm
        :if={@payslip_item_form_state != :closed}
        id="recurring_payslip_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <PayslipItemModelForm
        :if={@payslip_item_model_form_state != :closed}
        id="payslip_item_model_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <OutsideItemForm
        :if={@outside_item_form_state != :closed}
        id="recurring_payslip_outside_item_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@registration}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <div class="flex items-center">
                  <span class="text-gray-500 font-medium tracking-wider mr-4">
                    Holerite Modelo
                  </span>

                  <MonthToggle
                    :if={@recurring_payslip_items != [] or @recurring_outside_items != []}
                    target={@target_date}
                    floor={Date.end_of_month(@registration.admission_date)}
                    previous="previous_month"
                    next="next_month"
                  />
                </div>

                <DropdownBtn>
                  <a
                    :if={@recurring_payslip_items == [] and @recurring_outside_items == []}
                    :on-click="open_new_payslip_items_from_payslip_template_form"
                    class="dropdown-item"
                  >
                    Items a partir de um Modelo de Holerite
                  </a>

                  <a :on-click="open_new_payslip_item_model_form" class="dropdown-item">Item a partir de um Modelo de Item de Holerite</a>
                  <a :on-click="open_new_payslip_item_form" class="dropdown-item">Item do holerite</a>
                  <a :on-click="open_new_outside_item_form" class="dropdown-item">Item fora do holerite</a>
                </DropdownBtn>
              </div>
            </th>
          </tr>

          <tr
            :if={@recurring_payslip_items != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Código</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Vencimentos</th>
            <th class="py-3 px-6 text-right">Descontos</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for item <- @recurring_payslip_items}
            <tr class="border-b hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                {item.code}
              </td>

              <td class="py-3 px-6 text-left">
                {item.description}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :credit, do: item.amount}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :debit, do: item.amount}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_payslip_item_delete_confirmation_dialog"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr :if={@recurring_payslip_items != []} class="border-b italic bg-gray-100 text-sm text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="2">Subtotais</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip_items_credit_subtotal)}</td>
            <td class="py-2 px-6 text-right">{format_amount(@payslip_items_debit_subtotal)}</td>
            <td></td>
          </tr>

          <tr :if={@recurring_payslip_items != []} class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="3">Líquido Holerite</td>
            <td class={"py-2", "px-6", "text-right", "text-red-500": Money.negative?(@payslip_total)}>{format_amount(@payslip_total)}</td>
            <td></td>
          </tr>

          <tr :if={Money.negative?(@payslip_total)} class="text-sm bg-gray-100 font-medium text-red-500 tracking-wider">
            <td class="py-2 px-6 text-center" colspan="5">
              O valor líquido do holerite não pode ser negativo. Favor ajustar antes de gerar um holerite.
            </td>
          </tr>

          {#for item <- @recurring_outside_items}
            <tr class="border-b hover:bg-gray-50">
              <td></td>

              <td class="py-3 px-6 text-left">
                {item.description}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :credit, do: item.amount}
              </td>

              <td class="py-3 px-6 text-right">
                {if item.entry_type == :debit, do: item.amount}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_payslip_item_delete_confirmation_dialog"
                    phx-value-item_id={item.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr :if={@recurring_outside_items != []} class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider">
            <td class="py-2 px-6 text-left" colspan="3">Total</td>
            <td class={"py-2", "px-6", "text-right", "text-red-500": Money.negative?(@net_total)}>{format_amount(@net_total)}</td>
            <td></td>
          </tr>

          <tr :if={Money.negative?(@net_total)} class="text-sm bg-gray-100 font-medium text-red-500 tracking-wider">
            <td class="py-2 px-6 text-center" colspan="5">
              O valor total não pode ser negativo. Favor ajustar antes de gerar um holerite.
            </td>
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
      item_id: nil,
      message: nil,
      payslip_item_form_state: :closed,
      payslip_item_model_form_state: :closed,
      outside_item_form_state: :closed,
      payslip_template_form_state: :closed,
      delete_confirmation_dialog_state: :closed
    ]
  end

  defp update_items(socket, date) do
    %{registration: registration} = socket.assigns

    items = HR.list_recurring_payslip_items_by_registration(registration, start_date: date)

    socket =
      socket
      |> assign(target_date: date)
      |> assign_items(items)
      |> assign_totals()

    {:noreply, socket}
  end

  defp assign_items(socket, items) do
    assign(
      socket,
      recurring_payslip_items: Enum.filter(items, &(&1.type in [:payslip_item, :payslip_item_model])),
      recurring_outside_items: Enum.filter(items, &(&1.type == :outside_item))
    )
  end

  defp assign_totals(socket) do
    %{assigns: %{recurring_payslip_items: recurring_payslip_items, recurring_outside_items: recurring_outside_items}} = socket

    payslip_items_credit_subtotal = Sig.sum_by(:credit, recurring_payslip_items)
    payslip_items_debit_subtotal = Sig.sum_by(:debit, recurring_payslip_items)

    credit_total = Money.add(Sig.sum_by(:credit, recurring_outside_items), payslip_items_credit_subtotal)
    debit_total = Money.add(Sig.sum_by(:debit, recurring_outside_items), payslip_items_debit_subtotal)

    assign(socket,
      payslip_items_credit_subtotal: payslip_items_credit_subtotal,
      payslip_items_debit_subtotal: payslip_items_debit_subtotal,
      payslip_total: Money.subtract(payslip_items_credit_subtotal, payslip_items_debit_subtotal),
      net_total: Money.subtract(credit_total, debit_total)
    )
  end
end
