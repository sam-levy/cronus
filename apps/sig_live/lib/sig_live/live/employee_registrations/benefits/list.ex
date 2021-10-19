defmodule SigLive.EmployeeRegistrations.Benefits.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Benefits.Form
  alias SigLive.EmployeeRegistrations.Benefits.BenefitFromModelForm

  prop registration, :struct, required: true
  prop benefits, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data benefit_from_model_form_state, :atom, default: :closed, values!: BenefitFromModelForm.states()
  data benefit_id, :string, default: nil

  @impl true
  def handle_event("open_new_benefit_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_benefit_form", %{"benefit-id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_edit_benefit_amount_form", %{"benefit-id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_amount_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_finalize_benefit_form", %{"benefit-id" => id}, socket) do
    {:noreply, assign(socket, form_state: :finalize_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_new_benefit_from_model_form", _, socket) do
    {:noreply, assign(socket, benefit_from_model_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_benefit_from_model_form", %{"benefit-id" => id}, socket) do
    {:noreply, assign(socket, benefit_from_model_form_state: :show_mode, benefit_id: id)}
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
        id="benefit_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        {=@form_state}
        {=@registration}
        {=@benefit_id}
      />

      <BenefitFromModelForm
        :if={@benefit_from_model_form_state != :closed}
        id="benefit_from_model_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        form_state={@benefit_from_model_form_state}
        {=@registration}
        {=@benefit_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Benefícios
                </span>

                <DropdownBtn>
                  <a :on-click="open_new_benefit_form" class="dropdown-item">Novo benefício</a>
                  <a :on-click="open_new_benefit_from_model_form" class="dropdown-item">Benefício a partir de modelo</a>
                </DropdownBtn>
              </div>
            </th>
          </tr>

          <tr
            :if={@benefits != []}
            class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Tipo</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Valor</th>
            <th class="py-3 px-6 text-right">Início</th>
            <th class="py-3 px-6 text-right">Término</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for benefit <- @benefits}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                <a
                  :on-click={if benefit.is_from_model, do: "open_show_benefit_from_model_form", else: "open_show_benefit_form"}
                  phx-value-benefit_id={benefit.id}
                  class="cursor-pointer hover:underline"
                >
                  {capitalize_type(benefit.type)}
                </a>

                <span :if={benefit.is_for_dependent} class="ml-2 label-gray">
                  Dependente
                </span>
              </td>

              <td class="py-3 px-6 text-left">
                {benefit.description}
              </td>

              <td class="py-3 px-6 text-right">
                {format_amount(benefit.amount)}
              </td>

              <td class="py-3 px-6 text-right">
                {format_date(benefit.start_date)}
              </td>

              <td class="py-3 px-6 text-right">
                {format_date(benefit.end_date)}
              </td>

              <td class="pr-5 text-right">
                <span :if={is_nil(benefit.end_date)}>
                  <DropdownOpts>
                    <a
                      :if={!benefit.is_from_model}
                      :on-click="open_edit_benefit_amount_form"
                      phx-value-benefit_id={benefit.id}
                      class="dropdown-item"
                    >
                      Alterar Valor
                    </a>

                    <a
                      :on-click="open_finalize_benefit_form"
                      phx-value-benefit_id={benefit.id}
                      class="dropdown-item"
                    >
                      Finalizar Benefício
                    </a>
                  </DropdownOpts>
                </span>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]
  defp closed_state, do: [form_state: :closed, benefit_from_model_form_state: :closed, benefit_id: nil]
end
