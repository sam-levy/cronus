defmodule SigLive.Components.DropdownOpts do
  use SigLive, :surface_component

  alias SigLive.Components.Dropdown

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="relative" x-data="{ isOpen: false }" @click.away="isOpen = false">
      <div>
        <button
          type="button"
          class="dropdown-opts-btn"
          aria-expanded="true"
          aria-haspopup="true"
          @click="isOpen = !isOpen"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
            />
          </svg>
        </button>
      </div>

      <Dropdown.List>
        <#slot />
      </Dropdown.List>
    </div>
    """
  end
end
