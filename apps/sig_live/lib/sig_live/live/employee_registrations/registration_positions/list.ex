defmodule SigLive.EmployeeRegistrations.RegistrationPositions.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.RegistrationPositions.Form

  prop org, :struct, required: true
  prop registration, :struct, required: true
  prop registration_positions, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data confirmation_dialog_state, :atom, default: :closed
  data registration_position_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def handle_event("open_new_registration_position_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event(
        "open_edit_registration_position_form",
        %{"registration_position_id" => id},
        socket
      ) do
    {:noreply, assign(socket, form_state: :edit_mode, registration_position_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"registration_position_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, registration_position_id: id)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("delete_registration_position", _, socket) do
    %{registration: registration, registration_position_id: id} = socket.assigns

    with {:ok, registration_position} <- HR.fetch_registration_position(registration, id),
         {:ok, _registration_position} <- HR.delete_registration_position(registration_position) do
      HR.broadcast_updated_registration_positions(registration)
      flash_info("Cargo removido")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="registration_position_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@org}
        {=@registration}
        {=@registration_position_id}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_registration_position"
        dialog_title="Confirmar Remoção do Cargo"
        confirmation_msg="Deseja realmente remover esta designação? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="3">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Histórico de Cargos
                </span>

                <ButtonPlus on_click="open_new_registration_position_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@registration_positions != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 pl-6 pr-3 text-left">Cargo</th>
            <th class="py-3 px-3 text-right">Início</th>
            <th class="py-3 px-3 text-right" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for registration_position <- @registration_positions}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                phx-value-registration_position_id={registration_position.id}
                class="py-3 pl-6 pr-3 text-left"
              >
                {registration_position.position.name}
              </td>

              <td class="py-3 px-3 text-right">
                {format_date(registration_position.start_date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_registration_position_form"
                    phx-value-registration_position_id={registration_position.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-registration_position_id={registration_position.id}
                    class="dropdown-item"
                  >
                    <span class="text-red-500">Remover</span>
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
      form_state: :closed,
      confirmation_dialog_state: :closed,
      registration_position_id: nil
    ]
  end
end
