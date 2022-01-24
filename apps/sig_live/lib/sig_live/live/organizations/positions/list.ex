defmodule SigLive.Organizations.Positions.List do
  use SigLive, :surface_live_component

  alias Sig.Organizations

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.Organizations.Positions.Form

  prop org_positions, :list, required: true
  prop org, :struct, required: true

  data org_position_id, :string, default: nil
  data form_state, :atom, default: :closed
  data confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_org_position_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_org_position_form", %{"org_position_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, org_position_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"org_position_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, org_position_id: id)}
  end

  @impl true
  def handle_event("delete_org_position", _, socket) do
    %{org_positions: org_positions, org_position_id: org_position_id} = socket.assigns

    with {:ok, org_position} <- fetch_org_position(org_positions, org_position_id),
         {:ok, org_position} <- Organizations.delete_org_position(org_position) do
      Organizations.broadcast_deleted_org_position(org_position)
      flash_info("Setor removido")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_org_position(org_positions, org_position_id) do
    case Enum.find(org_positions, &(&1.id == org_position_id)) do
      nil -> {:error, "Setor não encontrado"}
      org_position -> {:ok, org_position}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="org_position_create_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@org_position_id}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_org_position"
        dialog_title="Confirmar Remoção do Setor"
        confirmation_msg="Deseja realmente remover o setor? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Cargos
                </span>

                <ButtonPlus on_click="open_new_org_position_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@org_positions != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 pl-6 text-left">Nome</th>
            <th class="py-3 px-3 text-left" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for org_position <- @org_positions}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {org_position.name}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_org_position_form"
                    phx-value-org_position_id={org_position.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-org_position_id={org_position.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      message: nil,
      org_position_id: nil,
      form_state: :closed,
      confirmation_dialog_state: :closed
    ]
  end
end
