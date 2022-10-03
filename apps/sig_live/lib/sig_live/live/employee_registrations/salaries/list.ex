defmodule SigLive.EmployeeRegistrations.Salaries.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Salaries.Form

  prop registration, :struct, required: true
  prop salaries, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data confirmation_dialog_state, :atom, default: :closed
  data salary_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def handle_event("open_new_salary_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_salary_form", %{"salary_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, salary_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"salary_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, salary_id: id)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("delete_salary", _, socket) do
    %{registration: registration, salary_id: id} = socket.assigns

    with {:ok, salary} <- HR.fetch_salary(registration, id),
         {:ok, _salary} <- HR.delete_salary(salary) do
      HR.broadcast_registration_salaries(registration)
      flash_info("Salário removido")

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
        id="salary_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@registration}
        {=@salary_id}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_salary"
        dialog_title="Confirmar Remoção da Salário"
        confirmation_msg="Deseja realmente remover este salário? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="3">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Histórico de Salários
                </span>

                <ButtonPlus on_click="open_new_salary_form" />
              </div>
            </th>
          </tr>

          <tr class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Valor</th>
            <th class="py-3 px-3 text-left">Início</th>
            <th />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for salary <- @salaries}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {format_amount(salary.amount)}
              </td>

              <td class="px-3 text-left select-all">
                {format_date(salary.start_date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a :on-click="open_edit_salary_form" phx-value-salary_id={salary.id} class="dropdown-item">
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-salary_id={salary.id}
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
      salary_id: nil
    ]
  end
end
