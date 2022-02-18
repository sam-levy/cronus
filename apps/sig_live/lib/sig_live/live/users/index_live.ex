defmodule SigLive.Users.IndexLive do
  use SigLive, :surface_live_view

  alias Sig.Accounts

  alias SigLive.Components.AppMenu
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.Users.NewUserForm

  defp user_opts, do: [preload: :individual, order_by: [individual: :name]]

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket), do: Accounts.subscribe_to_users(org)

    socket =
      assign(socket,
        new_user_form_open: false,
        users: Accounts.list_users(org, user_opts())
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
  def handle_event("disable_user", %{"user_id" => user_id}, socket) do
    %{org: org, users: users} = socket.assigns

    with {:ok, user} <- fetch_user(users, user_id),
         {:ok, _user} <- Accounts.disable_user(user) do
      flash_info("Usuário desbilitado")
      Accounts.broadcast_users(org, user_opts())

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("enable_user", %{"user_id" => user_id}, socket) do
    %{org: org, users: users} = socket.assigns

    with {:ok, user} <- fetch_user(users, user_id),
         {:ok, _user} <- Accounts.enable_user(user) do
      flash_info("Usuário habilitado")
      Accounts.broadcast_users(org, user_opts())

      {:noreply, socket}
    else
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp fetch_user(users, user_id) do
    case Enum.find(users, &(&1.id == user_id)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
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
        broadcast_opts={user_opts()}
        {=@org}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="3">
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
            <th class="py-3 px-3 text-left" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for user <- @users}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {user.individual.name}

                <span :if={user.disabled_at != nil} class="label-gray ml-1">
                  Desabilitado
                </span>
              </td>

              <td class="py-3 px-3 text-left select-all">
                {user.email}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  {#if user.disabled_at == nil}
                    <a :on-click="disable_user" phx-value-user_id={user.id} class="dropdown-item">
                      Desabilitar usuário
                    </a>
                  {#else}
                    <a :on-click="enable_user" phx-value-user_id={user.id} class="dropdown-item">
                      Habilitar usuário
                    </a>
                  {/if}
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
    [new_user_form_open: false]
  end
end
