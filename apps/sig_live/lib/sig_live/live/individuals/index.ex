defmodule SigLive.Individuals.Index do
  use SigLive, :surface_live_view

  alias Sig.Entities

	alias SigLive.Individuals.New

  @impl true
  def mount(%{"organization_id" => organization_id}, _session, socket) do
		if connected?(socket), do: Entities.subscribe_to_organization_individuals(organization_id)

		socket = assign(socket,
			organization_id: organization_id,
			individuals: Entities.list_organization_individuals(organization_id),
			new_individual_modal_open: false
		)

		{:ok, socket, temporary_assigns: [individuals: []]}
  end

	@impl true
  def handle_info({:updated_organization_individuals, individuals}, socket) do
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
		<New
			:if={@new_individual_modal_open}
			id="new_individual_modal"
			close="toggle_new_individual_modal"
			{=@organization_id}
		/>

		<div class="min-w-screen min-h-screen bg-gray-200 flex justify-center">
			<div class="w-full lg:w-5/6">
				<div class="bg-white shadow-lg my-6 rounded-lg">
					<table class="min-w-max w-full table-auto ">
						<thead>
							<div class="flex justify-between items-center py-3 px-6">
								<h1 class="text-gray-500 font-medium tracking-wider">Pessoas</h1>

								<button
									:on-click="toggle_new_individual_modal"
									class="hover:bg-blue-200 hover:text-blue-800 group flex items-center rounded-md bg-blue-100 text-blue-600 text-sm font-medium px-4 py-2"
								>
									<svg class="group-hover:text-light-blue-600 text-light-blue-500 mr-2" width="12" height="20" fill="currentColor">
										<path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
									</svg>

									Adicionar
								</button>
							</div>

							<tr class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider">
								<th class="py-3 px-6 text-left">Nome</th>
								<th class="py-3 px-6 text-left">CPF</th>
							</tr>
						</thead>

						<tbody class="text-gray-600 text-sm font-light">
							{#for individual <- @individuals}
								<tr class="border-b border-gray-200 hover:bg-gray-50">
									<td class="py-3 px-6 text-left">
										<span>{individual.name}</span>
									</td>

									<td class="py-3 px-6 text-left">
										<span>{format_cpf(individual.cpf)}</span>
									</td>
								</tr>
							{/for}
						</tbody>
					</table>
				</div>
			</div>
		</div>
    """
  end
end
