defmodule SigLive.Individual.PersonalIinfo do
  use SigLive, :surface_live_component

  prop org, :struct, required: true
  prop individual, :struct, required: true

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="bg-white shadow-lg overflow-hidden">
        <div class="flex justify-between items-center py-3 px-6">
          <span class="text-gray-500 font-medium tracking-wider">
            Informações Pessoais
          </span>
        </div>

        <div class="border-t border-gray-200">
          <dl class="divide-y divide-gray-200">
            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Nome</dt>
              <dd class="text-sm text-gray-500">{@individual.name}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">CPF</dt>
              <dd class="text-sm text-gray-500">{format_cpf(@individual.cpf)}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end
end
