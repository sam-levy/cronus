defmodule SigLive.EmployeeRegistrations.Suspensions.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Suspensions.Form

  prop registration, :struct, required: true
  prop suspensions, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data suspension_id, :string, default: nil

  @impl true
  def handle_event("open_new_suspension_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_suspension_form", %{"suspension_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, suspension_id: id)}
  end

  @impl true
  def handle_event("open_show_suspension_form", %{"suspension_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, suspension_id: id)}
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
        id="suspension_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@suspension_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Suspensões
                </span>

                <ButtonPlus on_click="open_new_suspension_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@suspensions != []}
            class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Motivo</th>
            <th class="py-3 px-6 text-right">Início</th>
            <th class="py-3 px-6 text-right">Término</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for suspension <- @suspensions}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                :on-click="open_show_suspension_form"
                phx-value-suspension_id={suspension.id}
                class="py-3 pl-6 text-left cursor-pointer hover:underline"
              >
                {suspension.description}
              </td>

              <td class="py-3 pl-6 text-right">
                {format_date(suspension.start_date)}
              </td>

              <td class="py-3 pl-6 text-right">
                {format_date(suspension.end_date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a :on-click="open_edit_suspension_form" phx-value-suspension_id={suspension.id} class="dropdown-item">Editar</a>
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

  defp closed_state, do: [form_state: :closed, suspension_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
