defmodule SigLive.Components.Dropdown.List do
  use SigLive, :surface_component

  slot default, required: true

  prop class, :css_class, default: []
  prop open_state_var, :string, default: "isOpen"

  def render(assigns) do
    ~F"""
      <div
        class={handle_class(@class)}
        x-cloak
        x-show={@open_state_var}
        @click={click(@open_state_var)}
        x-transition:enter="transition ease-out duration-75"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
      >
        <#slot />
      </div>
    """
  end

  defp handle_class(class), do: ~w(dropdown-list) ++ class

  defp click(open_state_var), do: "#{open_state_var} = false"
end
