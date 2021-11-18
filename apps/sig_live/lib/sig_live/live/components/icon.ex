defmodule SigLive.Components.Icon.Content do
  use SigLive, :surface_component

  prop name, :string

  def render(%{name: "lock_closed"} = assigns) do
    ~F"""
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
    """
  end

  def render(%{name: "lock_open"} = assigns) do
    ~F"""
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
    """
  end

  def render(assigns) do
    ~F"""
    <div></div>
    """
  end
end

defmodule SigLive.Components.Icon do
  use SigLive, :surface_component

  alias SigLive.Components.Icon.Content

  prop class, :css_class, default: []
  prop name, :string

  def render(assigns) do
    ~F"""
    <svg xmlns="http://www.w3.org/2000/svg" class={handle_class(@class)} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <Content name={@name}/>
    </svg>
    """
  end

  @base_class ~w(text-gray-400 h-6 w-6)

  defp handle_class(class), do: @base_class ++ class
end
