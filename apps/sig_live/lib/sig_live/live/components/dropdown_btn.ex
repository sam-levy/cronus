defmodule SigLive.Components.DropdownBtn do
  use SigLive, :surface_component

  prop text, :string, required: true

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div
      class="relative"
      x-data="{ isOpen: false }"
      @click.away="isOpen = false"
    >
      <button class="btn-blue" @click="isOpen = !isOpen">
        <svg
          :class="{ 'rotate-90': isOpen, 'rotate-0': !isOpen }"
          class="group-hover:text-light-blue-600 text-light-blue-500 mr-2 transition-transform duration-200 transform"
          width="12"
          height="20"
          fill="currentColor"
        >
          <path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
        </svg>

        {@text}
      </button>
      <div
        class="dropdown-list"
        x-cloak
        x-show="isOpen"
        @click="isOpen = false"
        x-transition:enter="transition ease-out duration-75"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
      >
        <#slot />
      </div>
    </div>
    """
  end
end
