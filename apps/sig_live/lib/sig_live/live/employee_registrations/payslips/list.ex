defmodule SigLive.EmployeeRegistrations.Payslips.List do
  use SigLive, :surface_live_component

  alias SigLive.EmployeeRegistrations.Payslips.Form
  alias SigLive.Components.Icon

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
    <div class="w-full flex flex-col items-end space-y-4">
      <Form
        :if={@form_state != :closed}
        id="payslip_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@payslip_id}
      />

      <div class="w-full mb-2">
        <button :on-click="open_form" class="w-full btn-dark-gray flex justify-center">
          <svg class="" width="12" height="20" fill="currentColor">
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"
            />
          </svg>

          <span class="ml-2">
            Holerite
          </span>
        </button>
      </div>

      <div
        class="w-full space-y-3 overflow-y-auto scrollbar-none pb-5"
        style="height: calc(100vh - 180px);"
      >
        {#for payslip <- @payslips}
          <div
            :on-click={@select_payslip}
            phx-value-payslip_id={payslip.id}
            class={classes_for_card(payslip.id, @selected_payslip_id)}
          >
            <div class="text-gray-500">
              {format_month(payslip.start_date)}
            </div>

            <div class="flex">
              <div :if={payslip.type != :regular} class={~w(text-xs) ++ payslip_type_text_color(payslip.type)}>
                {capitalize_type(payslip.type)}
              </div>

              <Icon name="lock_open" :if={!payslip.is_closed} size="4" class="ml-2" />
            </div>
          </div>
        {/for}
      </div>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, payslip_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]

  defp classes_for_card(id, id), do: ~w(border-blue-500) ++ base_card_classes()
  defp classes_for_card(_id, _selected_id), do: ~w(border-white) ++ base_card_classes()

  defp base_card_classes do
    ~w(flex justify-between items-center bg-white shadow-md py-2 px-3 text-sm rounded-md border-2 cursor-pointer select-none)
  end
end
