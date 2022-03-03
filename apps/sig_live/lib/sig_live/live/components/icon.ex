defmodule SigLive.Components.Icon.Content do
  use SigLive, :surface_component

  prop name, :string

  def render(%{name: "lock_closed"} = assigns) do
    ~F"""
    <path
      stroke-linecap="round"
      stroke-linejoin="round"
      stroke-width="2"
      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
    />
    """
  end

  def render(%{name: "lock_open"} = assigns) do
    ~F"""
    <path
      stroke-linecap="round"
      stroke-linejoin="round"
      stroke-width="2"
      d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"
    />
    """
  end

  def render(%{name: "trash"} = assigns) do
    ~F"""
    <path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
    />
    """
  end

  def render(%{name: "check"} = assigns) do
    ~F"""
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
    """
  end

  def render(assigns) do
    ~F"""
    <div />
    """
  end
end

defmodule SigLive.Components.Icon do
  use SigLive, :surface_component

  alias SigLive.Components.Icon.Content

  prop class, :css_class, default: []
  prop size, :string, default: "6"
  prop name, :string

  def render(assigns) do
    ~F"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={handle_class(@class, @size)}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <Content name={@name} />
    </svg>
    """
  end

  @base_class ~w(text-gray-400)

  defp handle_class(class, size), do: @base_class ++ class ++ handle_size(size)

  defp handle_size(size), do: ["h-#{size} w-#{size}"]
end
