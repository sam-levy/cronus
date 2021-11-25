defmodule SigLive.PayslipGroups.List do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Surface.Components.LiveRedirect

  alias Sig.HR

  alias SigLive.Components.ButtonPlus

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_groups(org)
    end

    socket =
      assign(socket,
        message: nil,
        groups: HR.list_groups_by(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_payslip_group, group}, socket) do
    groups = Enum.sort_by([group | socket.assigns.groups], & &1.date, {:desc, Date})

    {:noreply, assign(socket, groups: groups)}
  end

  @impl true
  def handle_info({:deleted_payslip_group, group}, socket) do
    groups = Enum.reject(socket.assigns.groups, & &1.id == group.id)

    {:noreply, assign(socket, groups: groups)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_event("open_form", _, socket) do
    IO.puts("Open form")

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
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
                  Grupos de Holerites
                </span>

                <ButtonPlus on_click="open_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@groups != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Mês</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for group <- @groups}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left cursor-pointer hover:underline">
                <LiveRedirect
                  to={Routes.sig_payslip_groups_payslips_list_path(@socket, :payslips, @org, group)}
                  class="hover:underline"
                >
                  <span>{format_month(group.date)}</span>
                </LiveRedirect>
              </td>

              <td class="px-3 text-left">
                {format_type(group.type)}
              </td>

              <td class="pr-5 text-right">
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
      group_id: nil,
      message: nil,
      form_state: :closed
    ]
  end
end
