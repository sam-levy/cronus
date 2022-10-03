defmodule SigLive.Components.ConfirmationDialog do
  use SigLive, :surface_component

  alias SigLive.Components.Modal

  @dialog_states [:open, :closed]

  prop close_event, :event, required: true
  prop action_event, :event, required: true

  prop dialog_title, :string, default: "Confirmar"
  prop confirmation_msg, :string
  prop cancel_btn_msg, :string, default: "Cancelar"
  prop action_btn_msg, :string, default: "Confirmar"
  prop error_message, :string, default: nil

  slot default

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={@dialog_title} close={@close_event}>
      <h2 :if={@confirmation_msg} class="text-md leading-6 font-normal text-gray-600">{@confirmation_msg}</h2>

      <#slot :if={!@confirmation_msg}>
        <h2 class="text-md leading-6 font-normal text-gray-600">Confirmar a ação</h2>
      </#slot>

      <div :if={@error_message} class="mt-2 form-error-tag">{@error_message}</div>

      <div class="mt-6 flex justify-end select-none">
        <button :on-click={@close_event} class="mr-5 btn-gray">{@cancel_btn_msg}</button>
        <button :on-click={@action_event} class="btn-red focus:ring-2" phx-hook="FocusElement">{@action_btn_msg}</button>
      </div>
    </Modal>
    """
  end

  def states, do: @dialog_states
end
