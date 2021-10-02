defmodule SigLive.Components.ButtonPlus do
  use SigLive, :surface_component

  prop value, :string, required: true
  prop on_click, :event

  def render(assigns) do
    ~F"""
    <button :on-click={@on_click} class="btn-blue">
      <svg class="group-hover:text-light-blue-600 text-light-blue-500 mr-2" width="12" height="20" fill="currentColor">
        <path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
      </svg>

      {@value}
    </button>
    """
  end
end
