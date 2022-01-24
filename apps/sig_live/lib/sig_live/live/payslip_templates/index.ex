defmodule SigLive.PayslipTemplates.Index do
  use SigLive, :surface_live_view

  alias Sig.HR

  alias SigLive.Components.AppMenu
  alias SigLive.PayslipTemplates

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_payslip_templates(org)
    end

    socket =
      assign(socket,
        payslip_templates: HR.list_payslip_templates(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_payslip_template, new_payslip_template}, socket) do
    payslip_templates = socket.assigns.payslip_templates

    updated_payslip_templates = sort_payslip_templates([new_payslip_template | payslip_templates])

    {:noreply, assign(socket, payslip_templates: updated_payslip_templates)}
  end

  @impl true
  def handle_info({:updated_payslip_template, %{id: id} = updated_payslip_template}, socket) do
    payslip_templates = socket.assigns.payslip_templates

    updated_payslip_templates =
      payslip_templates
      |> Enum.map(fn
        %{id: ^id} -> updated_payslip_template
        payslip_template -> payslip_template
      end)
      |> sort_payslip_templates()

    {:noreply, assign(socket, payslip_templates: updated_payslip_templates)}
  end

  @impl true
  def handle_info({:deleted_payslip_template, payslip_template}, socket) do
    payslip_templates = socket.assigns.payslip_templates

    updated_payslip_templates = Enum.reject(payslip_templates, &(&1.id == payslip_template.id))

    {:noreply, assign(socket, payslip_templates: updated_payslip_templates)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AppMenu>
        <AppMenu.Breadcrumb noslash name="Modelos" />
      </AppMenu>

      <PayslipTemplates.List id="payslip_templates_list" {=@payslip_templates} {=@org} />
    </div>
    """
  end

  defp sort_payslip_templates(payslip_templates) do
    Enum.sort_by(payslip_templates, & &1.name)
  end
end
