defmodule SigLive.Reports.HR do
  use SigLive, :surface_live_view

  alias Sig.Reports
  alias Sig.Entities

  alias SigLive.Components.AppMenu

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    {:ok, push_employee_count_per_designated_company(socket, org)}
  end

  defp push_employee_count_per_designated_company(socket, org) do
    data =
      org
      |> Reports.employee_count_per_designated_company()
      |> put_company_colors()

    push_event(socket, "employee_count_per_designated_company", %{data: data})
  end

  defp put_company_colors(data) do
    Map.new(data, fn {company_name, data} ->
      {company_name,
       Map.put(data, :color, Entities.get_company_color_by_trade_name(company_name))}
    end)
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

      <div class="w-full bg-white shadow-lg">
        <div class="py-3 px-6">
          <span class="text-gray-500 font-medium tracking-wider">
            Funcionários Por Empresa
          </span>
        </div>

        <div class="border-t border-gray-200 flex justify-center">
          <div class="w-96 p-3">
            <canvas
              id="employee_count_per_designated_company"
              phx-hook="employeeCountPerDesignatedCompany"
              phx-update="ignore"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
