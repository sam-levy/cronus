defmodule SigLive.EmployeeRegistrations.CompanyAssignments.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.CompanyAssignments.Form

  prop org, :struct, required: true
  prop registration, :struct, required: true
  prop company_assignments, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data confirmation_dialog_state, :atom, default: :closed
  data company_assignment_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def handle_event("open_new_company_assignment_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_company_assignment_form", %{"company_assignment_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, company_assignment_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"company_assignment_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, company_assignment_id: id)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("delete_company_assignment", _, socket) do
    %{registration: registration, company_assignment_id: id} = socket.assigns

    with {:ok, company_assignment} <- HR.fetch_company_assignment(registration, id),
         {:ok, _company_assignment} <- HR.delete_company_assignment(company_assignment) do
      HR.broadcast_updated_company_assignments(registration)
      flash_info("Designação removida")

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
        id="company_assignment_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@org}
        {=@registration}
        {=@company_assignment_id}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_company_assignment"
        dialog_title="Confirmar Remoção da Designação"
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
                  Designações
                </span>

                <ButtonPlus on_click="open_new_company_assignment_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@company_assignments != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 pl-6 pr-3 text-left">Empresa</th>
            <th class="py-3 px-3 text-right">Início</th>
            <th class="py-3 px-3 text-right" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for company_assignment <- @company_assignments}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td phx-value-company_assignment_id={company_assignment.id} class="py-3 pl-6 pr-3 text-left">
                {company_assignment.assigned_company.trade_name}
              </td>

              <td class="py-3 px-3 text-right">
                {format_date(company_assignment.start_date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_company_assignment_form"
                    phx-value-company_assignment_id={company_assignment.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-company_assignment_id={company_assignment.id}
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
      form_state: :closed,
      confirmation_dialog_state: :closed,
      company_assignment_id: nil
    ]
  end
end
