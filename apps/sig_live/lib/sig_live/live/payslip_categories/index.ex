defmodule SigLive.PayslipCategories.Index do
  use SigLive, :surface_live_view

  alias Sig.HR

  alias SigLive.PayslipCategories

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_payslip_categories(org)
    end

    socket =
      assign(socket,
        payslip_categories: HR.list_payslip_categories(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_payslip_category, new_payslip_category}, socket) do
    payslip_categories = socket.assigns.payslip_categories

    updated_payslip_categories =
      sort_payslip_categories([new_payslip_category | payslip_categories])

    {:noreply, assign(socket, payslip_categories: updated_payslip_categories)}
  end

  @impl true
  def handle_info({:updated_payslip_category, %{id: id} = updated_payslip_category}, socket) do
    payslip_categories = socket.assigns.payslip_categories

    updated_payslip_categories =
      payslip_categories
      |> Enum.map(fn
        %{id: ^id} -> updated_payslip_category
        payslip_category -> payslip_category
      end)
      |> sort_payslip_categories()

    {:noreply, assign(socket, payslip_categories: updated_payslip_categories)}
  end

  @impl true
  def handle_info({:deleted_payslip_category, payslip_category}, socket) do
    payslip_categories = socket.assigns.payslip_categories

    updated_payslip_categories = Enum.reject(payslip_categories, &(&1.id == payslip_category.id))

    {:noreply, assign(socket, payslip_categories: updated_payslip_categories)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <PayslipCategories.List id="payslip_categories_list" {=@payslip_categories} {=@org} />
    </div>
    """
  end

  defp sort_payslip_categories(payslip_categories) do
    Enum.sort_by(payslip_categories, & &1.code)
  end
end
