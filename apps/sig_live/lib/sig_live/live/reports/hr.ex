defmodule SigLive.Reports.HR do
  use SigLive, :surface_live_view

  alias SigLive.Components.AppMenu

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu id="app_menu" {=@org}>
        <AppMenu.Breadcrumb noslash name="Relatórios" />
        <AppMenu.Breadcrumb name="RH" />
      </AppMenu>

    </div>
    """
  end
end
