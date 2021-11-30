defmodule SigLive.Components.ToggleIcon do
  use SigLive, :surface_component

  alias SigLive.Components.Icon

  prop is_active, :boolean, default: false
  prop toggle, :event, required: true
  prop class, :css_class, default: []

  prop active_icon, :string, default: ""
  prop inactive_icon, :string, default: ""

  prop active_icon_class, :css_class, default: ""
  prop inactive_icon_class, :css_class, default: ""

  def render(assigns) do
    ~F"""
    <div class={handle_class(@class)} :on-click={@toggle}>
      <Icon name={@active_icon} class={@active_icon_class} :if={@is_active} />
      <Icon name={@inactive_icon} class={@inactive_icon_class} :if={!@is_active} />
    </div>
    """
  end

  @base_class ~w(hover:bg-gray-100 p-1 rounded-md cursor-pointer)

  defp handle_class(class), do: @base_class ++ class
end
