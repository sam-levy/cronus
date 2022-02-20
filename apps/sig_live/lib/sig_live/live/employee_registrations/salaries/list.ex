defmodule SigLive.EmployeeRegistrations.Salaries.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Salaries.Form

  prop registration, :struct, required: true
  prop salaries, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data salary_id, :string, default: nil

  @impl true
  def handle_event("open_new_salary_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_salary_form", %{"salary_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, salary_id: id)}
  end

  @impl true
  def handle_event("close_form", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="salary_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@salary_id}
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
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, salary_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
