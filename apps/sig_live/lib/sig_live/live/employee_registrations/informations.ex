defmodule SigLive.EmployeeRegistrations.Information do
  use SigLive, :surface_component

  prop registration, :struct, required: true

  @impl true
  def render(assigns) do
    ~F"""
    <div class="bg-white shadow-lg overflow-hidden">
      <div class="px-4 py-4">
        <span class="text-gray-500 font-medium tracking-wider">Registro</span>
      </div>

      <div class="border-t border-gray-200">
        <dl>
          <div class="px-4 py-2 bg-gray-100 grid grid-cols-2">
            <dt class="text-sm font-medium text-gray-500">Data de admissão</dt>
            <dd class="mt-1 text-sm text-gray-500">{format_date(@registration.admission_date)}</dd>
          </div>

          <div class="px-4 py-2 grid grid-cols-2">
            <dt class="text-sm font-medium text-gray-500">Número do registro</dt>
            <dd class="mt-1 text-sm text-gray-500">{@registration.number}</dd>
          </div>

          <div class="px-4 py-2 bg-gray-100 grid grid-cols-2">
            <dt class="text-sm font-medium text-gray-500">Matrícula eSocial</dt>
            <dd class="mt-1 text-sm text-gray-500">{@registration.e_social_number}</dd>
          </div>
        </dl>
      </div>
    </div>
    """
  end
end
