defmodule SigLive.Components.AppMenu do
  use SigLive, :surface_component

  alias SigLive.Components.AppMenu.Breadcrumb

  slot default

  @impl true
  def render(assigns) do
    ~F"""
    <div class="flex my-4 font-light">
      <#slot />
    </div>
    """
  end
end

defmodule SigLive.Components.AppMenu.Breadcrumb do
  use SigLive, :surface_component

  alias Surface.Components.LivePatch

  prop name, :string, required: true
  prop path, :string
  prop noslash, :boolean, default: false

  @impl true
  def render(assigns) do
    ~F"""
    <div class="" style="font-size: 15px;">
      <span :if={!@noslash} class="text-gray-400 font-thin">/</span>

      {#if @path}
        <LivePatch to={@path} class={item_class()}>
          {@name}
        </LivePatch>
      {#else}
        <span class={~w(cursor-default) ++ item_class()}>
          {@name}
        </span>
      {/if}
    </div>
    """
  end

  defp item_class do
    ~w(p-1 mr-1 text-gray-500 hover:bg-gray-300 rounded)
  end
end
