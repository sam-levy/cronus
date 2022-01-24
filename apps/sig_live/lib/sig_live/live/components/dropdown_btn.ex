defmodule SigLive.Components.DropdownBtn do
  use SigLive, :surface_component

  prop text, :string
  prop disabled, :boolean, default: false

  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="relative" x-data="{ isOpen: false }" @click.away="isOpen = false">
      <button class={handle_btn_class(@disabled)} @click="isOpen = !isOpen">
        <svg
          :class="{ 'rotate-90': isOpen, 'rotate-0': !isOpen }"
          class={handle_svg_class(@disabled)}
          width="12"
          height="20"
          fill="currentColor"
        >
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"
          />
        </svg>

        <span :if={@text} class="select-none ml-2">{@text}</span>
      </button>
      <div
        :if={!@disabled}
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
        <#slot :if={!@disabled} />
      </div>
    </div>
    """
  end

  defp handle_btn_class(false), do: "btn-blue"
  defp handle_btn_class(true), do: "btn bg-gray-100 text-gray-400"

  @svg_base_class ~w(group-hover:text-light-blue-600 text-light-blue-500)

  defp handle_svg_class(false), do: @svg_base_class ++ ~w(transition-transform duration-200 transform)
  defp handle_svg_class(true), do: @svg_base_class
end
