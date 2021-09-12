defmodule SigLive.Components.DropdownButton do
  use SigLive, :surface_component

  def render(assigns) do
    ~F"""
    <div
      x-data="{ open: false }"
      @click.away="open = false"
      class="relative self-center"
    >
      <button
        @click="open = !open"
        class="hover:bg-blue-200 hover:text-blue-800 group flex items-center rounded-md bg-blue-100 text-blue-600 text-sm font-medium px-4 py-2"
      >
        <svg
          :class="{ 'rotate-90': open, 'rotate-0': !open }"
          class="group-hover:text-light-blue-600 text-light-blue-500 mr-2 transition-transform duration-200 transform"
          width="12" height="20" fill="currentColor"
        >
          <path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
        </svg>

        Adicionar
      </button>
      <div
        x-show="open"
        x-transition:enter="transition ease-out duration-100"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
        class="absolute z-10 right-0 w-full mt-2 origin-top-right shadow-md w-auto"
      >
        <div class="px-2 py-2 bg-white rounded-md shadow">
          <.item name="Remover" />
        </div>
      </div>
    </div>
    """
  end

  defp item(assigns) do
    ~F"""
    <div
      class="block px-4 py-2 mt-1 text-sm font-semibold rounded-lg mt-0 hover:bg-gray-100"
      href="#"
    >
      {@name}
    </div>
    """
  end
end
