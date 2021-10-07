defmodule SigLive.EmployeeRegistrations.Vouchers.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Vouchers.Form

  prop registration, :struct, required: true
  prop vouchers, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data voucher_id, :string, default: nil

  @impl true
  def handle_event("open_new_voucher_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_voucher_form", %{"voucher-id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, voucher_id: id)}
  end

  @impl true
  def handle_event("open_show_voucher_form", %{"voucher-id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, voucher_id: id)}
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
        id="voucher_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@voucher_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="sticky top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Benefícios
                </span>

                <ButtonPlus value="Adicionar" on_click="open_new_voucher_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@vouchers != []}
            class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Tipo</th>
            <th class="py-3 px-6 text-right">Valor</th>
            <th class="py-3 px-6 text-right">Início</th>
            <th class="py-3 px-6 text-right">Término</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for voucher <- @vouchers}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                :on-click="open_show_voucher_form"
                phx-value-voucher_id={voucher.id}
                class="py-3 pl-6 text-left cursor-pointer hover:underline"
              >
                {voucher.type}
              </td>

              <td class="py-3 pl-6 text-right">
                {format_amount(voucher.amount)}
              </td>

              <td class="py-3 pl-6 text-right">
                {format_date(voucher.start_date)}
              </td>

              <td class="py-3 pl-6 text-right">
                {format_date(voucher.end_date)}
              </td>

              <td class="pr-5 text-right">
                <span :if={is_nil(voucher.end_date)}>
                  <DropdownOpts>
                    <a :on-click="open_edit_voucher_form" phx-value-voucher_id={voucher.id} class="dropdown-item">Finalizar Benefício</a>
                  </DropdownOpts>
                </span>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, voucher_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
