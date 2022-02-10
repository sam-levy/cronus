defmodule SigLive.EmployeeRegistrations.Warnings.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Warnings.Form

  prop registration, :struct, required: true
  prop warnings, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data warning_id, :string, default: nil

  @impl true
  def handle_event("open_new_warning_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_warning_form", %{"warning_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, warning_id: id)}
  end

  @impl true
  def handle_event("open_show_warning_form", %{"warning_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, warning_id: id)}
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
        id="warning_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@warning_id}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="4">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Advertências
                </span>

                <ButtonPlus on_click="open_new_warning_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@warnings != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Motivo</th>
            <th class="py-3 px-6 text-left">Data</th>
            <th class="py-3 px-6 text-right" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for warning <- @warnings}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                :on-click="open_show_warning_form"
                phx-value-warning_id={warning.id}
                class="py-3 pl-6 text-left cursor-pointer hover:underline"
              >
                {warning.description}
              </td>

              <td class="py-3 pl-6 text-left">
                {format_date(warning.date)}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a :on-click="open_edit_warning_form" phx-value-warning_id={warning.id} class="dropdown-item">Editar</a>
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

  defp closed_state, do: [form_state: :closed, warning_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
