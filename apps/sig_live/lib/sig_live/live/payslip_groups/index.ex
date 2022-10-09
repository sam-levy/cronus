defmodule SigLive.PayslipGroups.Index do
  use SigLive, :surface_live_view

  alias Surface.Components.LiveRedirect

  alias Sig.HR

  alias SigLive.Components.AppMenu
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.PayslipGroups.Form

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_groups(org)
    end

    socket =
      assign(socket,
        message: nil,
        form_state: :closed,
        groups: HR.list_groups_by(org),
        group_id: nil,
        delete_group_confirmation_dialog_state: :closed
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_payslip_group, group}, socket) do
    groups = Enum.sort_by([group | socket.assigns.groups], & &1.date, {:desc, Date})

    {:noreply, assign(socket, groups: groups)}
  end

  @impl true
  def handle_info({:deleted_payslip_group, group}, socket) do
    groups = Enum.reject(socket.assigns.groups, &(&1.id == group.id))

    {:noreply, assign(socket, groups: groups)}
  end

  @impl true
  def handle_info("close_modals", socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_form", _, socket) do
    {:noreply, assign(socket, form_state: :open)}
  end

  @impl true
  def handle_event("open_delete_group_confirmation_dialog", %{"group_id" => id}, socket) do
    {:noreply, assign(socket, delete_group_confirmation_dialog_state: :open, group_id: id)}
  end

  @impl true
  def handle_event("delete_group", _, socket) do
    %{org: org, groups: groups, group_id: group_id} = socket.assigns

    with {:ok, group} <- fetch_group(groups, group_id),
         {:ok, _group} <- HR.delete_group_with_payslips(org, group) do
      flash_info("Grupo removido")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_group(groups, group_id) do
    case Enum.find(groups, &(&1.id == group_id)) do
      nil -> {:error, "Grupo não encontrado"}
      group -> {:ok, group}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu id="app_menu" {=@org}>
        <AppMenu.Breadcrumb noslash name="RH" />
        <AppMenu.Breadcrumb name="Holerites" />
      </AppMenu>

      <ConfirmationDialog
        :if={@delete_group_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_group"
        dialog_title="Confirmar Remoção dos Holerites"
        confirmation_msg="Deseja realmente remover todos os holerites deste grupo? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <Form
        :if={@form_state != :closed}
        id="batch_create_form"
        close_event="close_modals"
        close_fun={fn -> send(self(), "close_modals") end}
        {=@form_state}
        {=@org}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Holerites
                </span>

                <ButtonPlus on_click="open_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@groups != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Mês</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for group <- @groups}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                <LiveRedirect
                  to={Routes.sig_payslip_groups_show_path(@socket, :payslip_groups, @org, group)}
                  class="hover:underline"
                >
                  <span>{format_month(group.date)}</span>
                </LiveRedirect>
              </td>

              <td class={~w(px-3 text-left) ++ payslip_type_text_color(group.type)}>
                {capitalize_type(group.type)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_delete_group_confirmation_dialog"
                    phx-value-group_id={group.id}
                    class="dropdown-item"
                  >
                    <span class="text-red-500">Remover</span>
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

  defp closed_state do
    [
      message: nil,
      group_id: nil,
      form_state: :closed,
      delete_group_confirmation_dialog_state: :closed
    ]
  end
end
