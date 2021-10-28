defmodule SigLive.EmployeeRegistrations.Payslips.List do
  use SigLive, :surface_live_component

  alias SigLive.EmployeeRegistrations.Payslips.Form

  prop registration, :struct, required: true
  prop payslips, :list, required: true
  prop select_payslip, :event, required: true
  prop selected_payslip_id, :string, default: nil
  prop payslip_id, :string, default: nil

  data form_state, :atom, default: :closed, values!: Form.states()

  @impl true
  def handle_event("open_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("close_form", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="payslip_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        form_state={@form_state}
        {=@registration}
        {=@payslip_id}
      />

      <div class="w-full flex flex-col items-end space-y-4">
        <div class="mb-2">
          <button :on-click="open_form" class="btn-dark-gray flex-auto">
            <svg class="" width="12" height="20" fill="currentColor">
              <path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
            </svg>

            <span class="ml-2">Holerite</span>
          </button>
        </div>

        <div class="w-full space-y-3">
          {#for payslip <- @payslips}
            <div
              :on-click={@select_payslip}
              phx-value-payslip_id={payslip.id}
              class={classes_for_card(payslip.id, @selected_payslip_id)}
            >
              <div class="text-gray-500">
                {format_month(payslip.start_date)}
              </div>

              <div :if={payslip.type != :regular} class={classes_for_type(payslip.type)}>
                {format_type(payslip.type)}
              </div>
            </div>
          {/for}
        </div>
      </div>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, payslip_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]

  defp classes_for_type(:vacation), do: ~w(text-blue-400) ++ type_base_classes()
  defp classes_for_type(_type), do: ~w(text-gray-400) ++ type_base_classes()

  defp type_base_classes, do: ~w(text-xs rounded)

  defp classes_for_card(id, id), do: ~w(border-blue-500) ++ base_card_classes()
  defp classes_for_card(_id, _selected_id), do: ~w(border-white) ++ base_card_classes()

  defp base_card_classes do
    ~w(flex justify-between items-center bg-white shadow-md py-2 px-3 text-sm rounded-md border-2 cursor-pointer select-none)
  end
end
