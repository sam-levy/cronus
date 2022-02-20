defmodule SigLive.EmployeeRegistrations.Summary do
  use SigLive, :surface_live_component

  alias SigLive.Components.DropdownBtn
  alias SigLive.EmployeeRegistrations.Form
  alias SigLive.EmployeeRegistrations.ResignationForm

  alias Sig.HR

  @broadcast_opts [preload: [:registered_at, :sector, :position]]

  prop registration, :struct, required: true
  prop individual, :struct, required: true
  prop org, :struct, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data resignation_form_open, :boolean, default: false

  @impl true
  def handle_event("open_form", _, socket) do
    {:noreply, assign(socket, form_state: :edit_mode)}
  end

  @impl true
  def handle_event("open_registration_resignation_form", _, socket) do
    {:noreply, assign(socket, resignation_form_open: true)}
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("undo_resignation", _params, socket) do
    %{registration: registration, individual: individual} = socket.assigns

    with {:ok, registration} <- HR.undo_registration_resignation(registration) do
      HR.broadcast_updated_individual_registration(individual, registration, @broadcast_opts)
      flash_info("Desligamento desfeito")

      {:noreply, socket}
    else
      {:error, changeset} when is_struct(changeset) ->
        flash_error(Sig.Changeset.errors_to_string(changeset))

        {:noreply, socket}

      {:error, message} when is_binary(message) ->
        flash_error(message)

        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="registration_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        registration_id={@registration.id}
        {=@form_state}
        {=@individual}
        {=@org}
      />

      <ResignationForm
        :if={@resignation_form_open}
        id="registration_resignation_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        registration_id={@registration.id}
        {=@individual}
      />

      <div class="bg-white shadow-lg overflow-hidden">
        <div class="flex justify-between items-center py-3 px-6">
          <span class="text-gray-500 font-medium tracking-wider">
            Registro
          </span>

          <DropdownBtn>
            <a :on-click="open_form" class="dropdown-item">Editar</a>

            {#if is_nil(@registration.resignation_date)}
              <a :on-click="open_registration_resignation_form" class="dropdown-item">Desligar Funcionário</a>
            {#else}
              <a :on-click="undo_resignation" class="dropdown-item">Desfazer Desligamento</a>
            {/if}
          </DropdownBtn>
        </div>

        <div class="border-t border-gray-200">
          <dl class="divide-y divide-gray-200">
            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Empresa</dt>
              <dd class="text-sm text-gray-500">{@registration.registered_at.registration_name}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Data de admissão</dt>
              <dd class="text-sm text-gray-500">{format_date(@registration.admission_date)}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Número do registro</dt>
              <dd class="text-sm text-gray-500">{@registration.number}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Matrícula eSocial</dt>
              <dd class="text-sm text-gray-500">{@registration.e_social_number}</dd>
            </div>

            <div class="px-4 py-2  grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Setor</dt>
              <dd class="text-sm text-gray-500">{@registration.sector.name}</dd>
            </div>

            <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
              <dt class="text-sm font-medium text-gray-500">Cargo</dt>
              <dd class="text-sm text-gray-500">{@registration.position.name}</dd>
            </div>

            {#if @registration.resignation_date}
              <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
                <dt class="text-sm font-medium text-gray-500">Data de desligamento</dt>
                <dd class="text-sm text-gray-500">{format_date(@registration.resignation_date)}</dd>
              </div>

              <div class="px-4 py-2 grid grid-cols-2 hover:bg-gray-50">
                <dt class="text-sm font-medium text-gray-500">Motivo do desligamento</dt>
                <dd class="text-sm text-gray-500">{capitalize_type(@registration.resignation_type)}</dd>
              </div>
            {/if}
          </dl>
        </div>
      </div>
    </div>
    """
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state, do: [form_state: :closed, resignation_form_open: false, registration_id: nil]
  defp closed_state(id), do: closed_state() ++ [id: id]
end
