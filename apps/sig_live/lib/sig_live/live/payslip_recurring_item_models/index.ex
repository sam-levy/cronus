defmodule SigLive.PayslipRecurringItemModels.Index do
  use SigLive, :surface_live_view

  alias Sig.HR

  alias SigLive.PayslipRecurringItemModels

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_payslip_recurring_item_models(org)
    end

    socket =
      assign(socket,
        payslip_recurring_item_models:
          HR.list_payslip_recurring_item_models(org, preload: :category)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _socket, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_payslip_recurring_item_model, new_model}, socket) do
    models = socket.assigns.payslip_recurring_item_models

    updated_models = sort_payslip_recurring_item_models([new_model | models])

    {:noreply, assign(socket, payslip_recurring_item_models: updated_models)}
  end

  @impl true
  def handle_info({:updated_payslip_recurring_item_model, %{id: id} = updated_model}, socket) do
    models = socket.assigns.payslip_recurring_item_models

    updated_models =
      models
      |> Enum.map(fn
        %{id: ^id} -> updated_model
        model -> model
      end)
      |> sort_payslip_recurring_item_models()

    {:noreply, assign(socket, payslip_recurring_item_models: updated_models)}
  end

  @impl true
  def handle_info({:deleted_payslip_recurring_item_model, model}, socket) do
    models = socket.assigns.payslip_recurring_item_models

    updated_models = Enum.reject(models, &(&1.id == model.id))

    {:noreply, assign(socket, payslip_recurring_item_models: updated_models)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <PayslipRecurringItemModels.List
        id="payslip_recurring_item_models_list"
        {=@payslip_recurring_item_models}
        {=@org}
      />
    </div>
    """
  end

  defp sort_payslip_recurring_item_models(models) do
    Enum.sort_by(models, & &1.category.code)
  end
end
