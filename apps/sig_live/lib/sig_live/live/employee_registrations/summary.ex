defmodule SigLive.EmployeeRegistrations.Summary do
  use SigLive, :surface_live_component

  alias SigLive.Components.DropdownBtn
  alias SigLive.EmployeeRegistrations.Form

  prop registration, :struct, required: true
  prop individual, :struct, required: true
  prop org, :struct, required: true

  data form_state, :atom, default: :closed, values!: Form.states()

  @impl true
  def handle_event("open_form", _, socket) do
    {:noreply, assign(socket, form_state: :edit_mode)}
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
        registration_id={@registration.id}
        {=@form_state}
        {=@individual}
        {=@org}
      />

      <div class="bg-white shadow-lg overflow-hidden">
        <div class="flex justify-between items-center py-3 px-6">
          <span class="text-gray-500 font-medium tracking-wider">
            Registro
          </span>

          <DropdownBtn>
            <a :on-click="open_form" class="dropdown-item">Editar</a>
          </DropdownBtn>
        </div>

        <div class="border-t border-gray-200">
          <dl class="divide-y divide-gray-200">
            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Empresa</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.registered_at.registration_name}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Data de admissão</dt>
              <dd class="mt-1 text-sm text-gray-500">{format_date(@registration.admission_date)}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Número do registro</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.number}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Matrícula eSocial</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.e_social_number}</dd>
            </div>

            <div class="px-4 py-2  grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Setor</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.sector.name}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Cargo</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.position.name}</dd>
            </div>

            <div :if={@registration.resignation_date} class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Data de desligamento</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.resignation_date}</dd>
            </div>

            <div :if={@registration.resignation_date} class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Tipo de desligamento</dt>
              <dd class="mt-1 text-sm text-gray-500">{@registration.resignation_type}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, registration_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
