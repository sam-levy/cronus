defmodule SigLive.Components.DropdownOpts do
  use SigLive, :surface_component

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div
      class="relative"
      x-data="{ isOpen: false }"
      @click.away="isOpen = false"
    >
      <div>
        <button
          type="button"
          class="dropdown-opts-btn"
          id="menu-button"
          aria-expanded="true"
          aria-haspopup="true"
          @click="isOpen = !isOpen"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
          </svg>
        </button>
      </div>

      <div
        class="dropdown-opts-list"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="menu-button"
        tabindex="-1"
        x-show="isOpen"
        @click="isOpen = false"
      >
        <#slot />
      </div>
    </div>
    """
  end
end
