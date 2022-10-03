defmodule SigLive.EmployeeRegistrations.Benefits.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Benefits.Form
  alias SigLive.EmployeeRegistrations.Benefits.BenefitFromModelForm

  prop registration, :struct, required: true
  prop benefits, :list, required: true

  data form_state, :atom, default: :closed, values!: Form.states()
  data confirmation_dialog_state, :atom, default: :closed

  data benefit_from_model_form_state, :atom,
    default: :closed,
    values!: BenefitFromModelForm.states()

  data benefit_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_benefit_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_benefit_form", %{"benefit_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_edit_benefit_amount_form", %{"benefit_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_amount_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_finalize_benefit_form", %{"benefit_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :finalize_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_new_benefit_from_model_form", _, socket) do
    {:noreply, assign(socket, benefit_from_model_form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_benefit_from_model_form", %{"benefit_id" => id}, socket) do
    {:noreply, assign(socket, benefit_from_model_form_state: :show_mode, benefit_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"benefit_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, benefit_id: id)}
  end

  @impl true
  def handle_event("delete_benefit", _, socket) do
    %{registration: registration, benefit_id: id} = socket.assigns

    case HR.delete_benefit_by_id(registration, id) do
      {:ok, _benefit} ->
        HR.broadcast_registration_benefits(registration)
        flash_info("Benefício removido")

        {:noreply, assign(socket, closed_state())}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}

      {:error, message} ->
        {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="benefit_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@registration}
        {=@benefit_id}
      />

      <BenefitFromModelForm
        :if={@benefit_from_model_form_state != :closed}
        id="benefit_from_model_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        form_state={@benefit_from_model_form_state}
        {=@registration}
        {=@benefit_id}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_benefit"
        dialog_title="Confirmar Remoção do Benefício"
        action_btn_msg="Remover"
        error_message={@message}
      >
        <h2 class="text-md leading-6 font-normal text-gray-600">
          Caso deseje cancelar o benefício utilize a opção <strong><i>Finalizar Benefício</i></strong>.
        </h2>

        <br>

        <h2 class="text-md leading-6 font-normal text-gray-600">
          Deseja realmente remover este benefício? Esta ação não poderá ser desfeita.
        </h2>
      </ConfirmationDialog>

      <table class="w-full bg-white shadow-lg">
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
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Tipo</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Valor</th>
            <th class="py-3 px-6 text-right">Início</th>
            <th class="py-3 px-6 text-right">Término</th>
            <th class="py-3 px-6 text-right" />
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

                <span :if={benefit.is_from_model} class="ml-2 label-blue">
                  Do Modelo
                </span>

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
                <DropdownOpts>
                  <a
                    :if={is_active(benefit) and !benefit.is_from_model}
                    :on-click="open_edit_benefit_amount_form"
                    phx-value-benefit_id={benefit.id}
                    class="dropdown-item"
                  >
                    Atualizar Valor
                  </a>

                  <a
                    :if={is_active(benefit)}
                    :on-click="open_finalize_benefit_form"
                    phx-value-benefit_id={benefit.id}
                    class="dropdown-item"
                  >
                    Finalizar Benefício
                  </a>

                  <a
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-benefit_id={benefit.id}
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
      form_state: :closed,
      benefit_id: nil,
      benefit_from_model_form_state: :closed,
      confirmation_dialog_state: :closed
    ]
  end

  defp is_active(%{end_date: nil}), do: true
  defp is_active(_benefit), do: false
end
