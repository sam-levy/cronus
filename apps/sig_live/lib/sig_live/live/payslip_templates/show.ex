defmodule SigLive.PayslipTemplates.Show do
  use SigLive, :surface_live_view

  alias Sig.HR

  alias SigLive.PayslipTemplates.PayslipTemplateItems

  @impl true
  def mount(%{"id" => payslip_template_id}, _session, socket) do
    %{org: org} = socket.assigns

    payslip_template = HR.get_payslip_template(org, payslip_template_id)

    if connected?(socket) do
      HR.subscribe_to_payslip_template_items(payslip_template)
    end

    socket =
      assign(socket,
        payslip_template: payslip_template,
        payslip_template_items: HR.list_payslip_template_items(payslip_template)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_payslip_template_item, new_payslip_template_item}, socket) do
    payslip_template_items = socket.assigns.payslip_template_items

    updated_payslip_template_items =
      sort_payslip_template_items([new_payslip_template_item | payslip_template_items])

    {:noreply, assign(socket, payslip_template_items: updated_payslip_template_items)}
  end

  @impl true
  def handle_info({:deleted_payslip_template_item, deleted_payslip_template_item}, socket) do
    payslip_template_items = socket.assigns.payslip_template_items

    updated_payslip_template_items =
      Enum.reject(
        payslip_template_items,
        &(&1.payslip_recurring_item_model_id ==
            deleted_payslip_template_item.payslip_recurring_item_model_id)
      )

    {:noreply, assign(socket, payslip_template_items: updated_payslip_template_items)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <PayslipTemplateItems.List
        id="payslip_template_items_list"
        {=@payslip_template_items}
        {=@payslip_template}
        {=@org}
      />
    </div>
    """
  end

  defp sort_payslip_template_items(payslip_template_items) do
    Enum.sort_by(payslip_template_items, & &1.payslip_recurring_item_model.category.code)
  end
end
