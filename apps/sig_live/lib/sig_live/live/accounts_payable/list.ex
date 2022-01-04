defmodule SigLive.AccountsPayable.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.DropdownOpts

  prop org, :struct, required: true
  prop payables, :list, required: true

  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <table class="w-full bg-white shadow-lg my-5">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Contas a Pagar
                </span>
              </div>
            </th>
          </tr>

          <tr
            :if={@payables != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Vencimento</th>
            <th class="py-3 px-3 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Destinatário</th>
            <th class="py-3 px-2 text-left">Valor</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th class="py-3 text-left"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for payable <- @payables}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {format_date(payable.due_date)}
              </td>

              <td class="py-3 px-3 text-left">
                {payable.description}
              </td>

              <td class="py-3 px-3 text-left">
                {#if payable.target == :payslip}
                  {payable.individual.name}
                {/if}
              </td>

              <td class="py-3 px-3 text-left">
                {payable.amount}
              </td>

              <td class="py-3 px-3 text-left">
                {capitalize_type(payable.financial_transaction_type)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :if={payable.target == :payslip}
                    href={Routes.sig_employee_registrations_show_path(@socket, :payslip, @org, payable.payslip.registration_id, payable.payslip)}
                    target="_blank"
                    class="dropdown-item"
                  >
                    Visualizar holerite
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      message: nil,
      payable_id: nil
    ]
  end
end
