defmodule SigLive.Individuals.Index do
  use SigLive, :surface_live_view
  on_mount SigLive.InitAssigns

  alias Surface.Components.LiveRedirect

  alias Sig.Entities

  alias SigLive.Components.ButtonPlus
  alias SigLive.Individuals.New

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket), do: Entities.subscribe_to_individuals(org)

    socket =
      assign(socket,
        individuals: Entities.list_individuals(org),
        new_individual_modal_open: false
      )

    {:ok, socket, temporary_assigns: [individuals: []]}
  end

  @impl true
  def handle_info({:updated_individuals, individuals}, socket) do
    {:noreply, assign(socket, individuals: individuals)}
  end

  @impl true
  def handle_info("individual_created", socket) do
    socket =
      socket
      |> update(:new_individual_modal_open, &(!&1))
      |> put_flash(:info, "Pessoa adicionada")

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_new_individual_modal", _, socket) do
    {:noreply, update(socket, :new_individual_modal_open, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <New
        :if={@new_individual_modal_open}
        id="new_individual_modal"
        close="toggle_new_individual_modal"
        {=@org}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0">
        <tr class="bg-white">
          <th colspan="2">
            <div class="flex justify-between items-center py-3 px-6">
              <span class="text-gray-500 font-medium tracking-wider">Pessoas</span>

              <ButtonPlus on_click="toggle_new_individual_modal"/>
            </div>
          </th>
        </tr>

        <tr class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider">
          <th class="py-3 px-6 text-left">Nome</th>
          <th class="py-3 px-6 text-left">CPF</th>
        </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for individual <- @individuals}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                <LiveRedirect to={Routes.sig_individuals_show_path(@socket, :show, @org, individual.entity)} class="hover:underline">
                  <span>{individual.name}</span>
                </LiveRedirect>
              </td>

              <td class="py-3 px-6 text-left select-all">
                <span>{format_cpf(individual.cpf)}</span>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end
end
