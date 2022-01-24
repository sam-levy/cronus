defmodule SigLive.BenefitModels.Index do
  use SigLive, :surface_live_view

  alias Sig.HR

  alias SigLive.BenefitModels

  @impl true
  def mount(_params, _session, socket) do
    %{org: org} = socket.assigns

    if connected?(socket) do
      HR.subscribe_to_benefit_models(org)
    end

    socket =
      assign(socket,
        benefit_models: HR.list_benefit_models(org)
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_benefit_model, new_benefit_model}, socket) do
    benefit_models = socket.assigns.benefit_models

    updated_benefit_models = sort_benefit_models([new_benefit_model | benefit_models])

    {:noreply, assign(socket, benefit_models: updated_benefit_models)}
  end

  @impl true
  def handle_info({:updated_benefit_model, %{id: id} = updated_benefit_model}, socket) do
    benefit_models = socket.assigns.benefit_models

    updated_benefit_models =
      benefit_models
      |> Enum.map(fn
        %{id: ^id} -> updated_benefit_model
        benefit_model -> benefit_model
      end)
      |> sort_benefit_models()

    {:noreply, assign(socket, benefit_models: updated_benefit_models)}
  end

  @impl true
  def handle_info({:deleted_benefit_model, benefit_model}, socket) do
    benefit_models = socket.assigns.benefit_models

    updated_benefit_models = Enum.reject(benefit_models, &(&1.id == benefit_model.id))

    {:noreply, assign(socket, benefit_models: updated_benefit_models)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <BenefitModels.List id="benefit_models_list" {=@benefit_models} {=@org} />
    </div>
    """
  end

  defp sort_benefit_models(benefit_models) do
    Enum.sort_by(benefit_models, & &1.description)
  end
end
