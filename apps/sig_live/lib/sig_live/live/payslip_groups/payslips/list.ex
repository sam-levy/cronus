defmodule SigLive.PayslipGroups.Payslips.List do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Sig.HR

  alias SigLive.Components.Icon

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    %{org: org} = socket.assigns
    group = HR.get_group(org, id)

    socket =
      assign(socket,
        group: group,
        payslips: HR.list_payslips_by(group, preload_registration: true)
      )

    {:ok, socket, temporary_assigns: [payslips: []]}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Holerites {format_month(@group.date)}
                  <span class="text-gray-400 italic font-extralight">
                    {capitalize_type(@group.type)}
                  </span>
                </span>
              </div>
            </th>
          </tr>

          <tr
            :if={@payslips != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Funcionário</th>
            <th class="py-3 px-6 text-left">Empresa</th>
            <th></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for payslip <- @payslips}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 px-6 text-left cursor-pointer hover:underline">
                {payslip.registration.individual.name}
              </td>

              <td class="py-3 px-6 text-left">
                {payslip.registration.registered_at.trade_name}
              </td>

              <td class="pr-5 text-right">
                <div class="flex justify-end">
                  <Icon name="lock_open" :if={!payslip.is_closed} size="4" class="ml-2"/>
                </div>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end
end
