defmodule SigLive.Users.IndexLive do
  use SigLive, :surface_live_view

  alias Sig.Accounts

  alias SigLive.Components.AppMenu
  alias SigLive.Components.ButtonPlus
  alias SigLive.Users.NewUserForm

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket), do: Accounts.subscribe_to_users(org)

    socket =
      assign(socket,
        new_user_form_open: false,
        users: Accounts.list_users(org, preload: :individual, order_by: [individual: :name])
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("open_new_user_form", _, socket) do
    {:noreply, assign(socket, new_user_form_open: true)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_info("close_modals", socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_info({:updated_users, users}, socket) do
    {:noreply, assign(socket, users: users)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu id="app_menu" {=@org}>
        <AppMenu.Breadcrumb noslash name="Usuários" />
      </AppMenu>

      <NewUserForm
        :if={@new_user_form_open}
        id="new_user_form"
        close_event="close_modals"
        close_fun={fn -> send(self(), "close_modals") end}
        form_open={@new_user_form_open}
        broadcast_opts={preload: :individual}
        {=@org}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="2">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Usuários
                </span>

                <ButtonPlus on_click="open_new_user_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@users != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Nome</th>
            <th class="py-3 px-3 text-left">Email</th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for user <- @users}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {user.individual.name}
              </td>

              <td class="py-3 px-3 text-left">
                {user.email}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  defp closed_state do
    [new_user_form_open: false]
  end
end
