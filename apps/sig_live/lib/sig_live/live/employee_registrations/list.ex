defmodule SigLive.EmployeeRegistrations.List do
  use SigLive, :surface_live_component

  alias Surface.Components.LiveRedirect

  alias SigLive.Components.ButtonPlus
  alias SigLive.EmployeeRegistrations.Form

  prop org, :struct, required: true
  prop individual, :struct, required: true
  prop employee_registrations, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data registration_id, :string, default: nil

  @impl true
  def handle_event("open_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
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
        id="registration_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@org}
        {=@individual}
        {=@registration_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="sticky top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Registros de Trabalho
                </span>

                <ButtonPlus on_click="open_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@employee_registrations != []}
            class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Empresa</th>
            <th class="py-3 px-3 text-left">Início</th>
            <th class="py-3 px-3 text-left">Término</th>
            <th class="py-3 px-3 text-left">Salário</th>
            <th></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for registration <- @employee_registrations}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                <LiveRedirect
                  to={Routes.sig_employee_registrations_show_path(@socket, :show, @org, @individual.entity_id, registration)}
                  class="hover:underline"
                >
                  <span>{registration.registered_at.registration_name}</span>
                </LiveRedirect>
              </td>

              <td class="px-3 text-left select-all">
                {format_date(registration.admission_date)}
              </td>

              <td class="px-3 text-left select-all">
                {format_date(registration.resignation_date)}
              </td>

              <td class="px-3 text-left">
                {format_amount(registration.salary_amount)}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, registration_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
