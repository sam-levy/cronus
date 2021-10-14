defmodule SigLive.Components.ConfirmationDialog do
  use SigLive, :surface_component

  alias SigLive.Components.Modal

  @dialog_states [:open, :closed]

  prop close_event, :event, required: true
  prop action_event, :event, required: true

  prop dialog_title, :string, default: "Confirmar"
  prop confirmation_msg, :string, default: "Confirmar a ação"
  prop cancel_btn_msg, :string, default: "Cancelar"
  prop action_btn_msg, :string, default: "Confirmar"

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={@dialog_title} close={@close_event}>
      <h2 class="text-md leading-6 font-normal text-gray-600">{@confirmation_msg}</h2>

      <div class="mt-6 flex justify-end">
        <a :on-click={@close_event} class="mr-5 btn-gray">{@cancel_btn_msg}</a>
        <a :on-click={@action_event} class="btn-red">{@action_btn_msg}</a>
      </div>
    </Modal>
    """
  end

  def states, do: @dialog_states
end
