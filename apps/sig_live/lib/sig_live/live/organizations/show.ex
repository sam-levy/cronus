defmodule SigLive.Organizations.Show do
  use SigLive, :surface_live_view

  alias Sig.Organizations

  alias SigLive.Organizations.Sectors
  alias SigLive.Organizations.Positions

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      Organizations.subscribe_to_org_sectors(org)
      Organizations.subscribe_to_org_positions(org)
    end

    socket =
      assign(socket,
        org_sectors: Organizations.list_org_sectors(org),
        org_positions: Organizations.list_org_positions(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_org_sector, new_org_sector}, socket) do
    org_sectors = socket.assigns.org_sectors

    updated_org_sectors = sort([new_org_sector | org_sectors])

    {:noreply, assign(socket, org_sectors: updated_org_sectors)}
  end

  @impl true
  def handle_info({:updated_org_sector, %{id: id} =  updated_org_sector}, socket) do
    org_sectors = socket.assigns.org_sectors

    updated_org_sectors =
      org_sectors
      |> Enum.map(fn
        %{id: ^id} -> updated_org_sector
        org_sector -> org_sector
      end)
      |> sort()

    {:noreply, assign(socket, org_sectors: updated_org_sectors)}
  end

  @impl true
  def handle_info({:deleted_org_sector, org_sector}, socket) do
    org_sectors = socket.assigns.org_sectors

    updated_org_sectors = Enum.reject(org_sectors, & &1.id == org_sector.id)

    {:noreply, assign(socket, org_sectors: updated_org_sectors)}
  end

  @impl true
  def handle_info({:new_org_position, new_org_position}, socket) do
    org_positions = socket.assigns.org_positions

    updated_org_positions = sort([new_org_position | org_positions])

    {:noreply, assign(socket, org_positions: updated_org_positions)}
  end

  @impl true
  def handle_info({:updated_org_position, %{id: id} =  updated_org_position}, socket) do
    org_positions = socket.assigns.org_positions

    updated_org_positions =
      org_positions
      |> Enum.map(fn
        %{id: ^id} -> updated_org_position
        org_position -> org_position
      end)
      |> sort()

    {:noreply, assign(socket, org_positions: updated_org_positions)}
  end

  @impl true
  def handle_info({:deleted_org_position, org_position}, socket) do
    org_positions = socket.assigns.org_positions

    updated_org_positions = Enum.reject(org_positions, & &1.id == org_position.id)

    {:noreply, assign(socket, org_positions: updated_org_positions)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="flex gap-4">
      <div class="w-1/2">
        <Sectors.List id="org_sectors_list" {=@org_sectors} {=@org}/>
      </div>

      <div class="w-1/2">
        <Positions.List id="org_positions_list" {=@org_positions} {=@org}/>
      </div>
    </div>
    """
  end

  defp sort(list), do: Enum.sort_by(list, & &1.name)
end
