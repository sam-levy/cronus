defmodule SigLive.EmployeeRegistrations.Salaries.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.ButtonPlus
  alias SigLive.EmployeeRegistrations.Salaries.Form

  prop registration, :struct, required: true
  prop salaries, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()

  @impl true
  def handle_event("new_salary", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("close_form", _, socket) do
    {:noreply, assign(socket, form_state: :closed)}
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
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="2">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Histórico de Salários
                </span>

                <ButtonPlus on_click="new_salary" />
              </div>
            </th>
          </tr>

          <tr class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Valor</th>
            <th class="py-3 px-3 text-left">Início</th>
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
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, id: id, form_state: :closed)
end
