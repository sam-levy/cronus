defmodule SigLive.Components.Switch do
  use SigLive, :surface_component

  prop is_active, :boolean, default: false
  prop toggle_is_active, :event, required: true

  def render(assigns) do
    ~F"""
    <div class="flex flex-col justify-center items-center">
      <div class="flex justify-center items-center">
        <div class={container_class(@is_active)} :on-click={@toggle_is_active}>
          <div class={switch_class(@is_active)} :on-click={@toggle_is_active}></div>
        </div>
      </div>
    </div>
    """
  end

  @container_base_class ~w(w-12 h-6 flex items-center rounded-full px-1)
  @switch_base_class ~w(bg-white w-4 h-4 rounded-full shadow-md transform)

  defp container_class(false), do: ~w(bg-gray-200) ++ @container_base_class
  defp container_class(true), do: ~w(bg-blue-600) ++ @container_base_class

  defp switch_class(false), do: @switch_base_class
  defp switch_class(true), do: ~w(translate-x-6) ++ @switch_base_class
end
