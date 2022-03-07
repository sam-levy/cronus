defmodule SigLive.BenefitModels.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.BenefitModels.Form

  prop org, :struct, required: true
  prop benefit_models, :list, required: true

  data benefit_model_id, :string, default: nil
  data message, :string, default: nil

  data form_state, :atom, default: :closed, values!: Form.states()

  data enable_benefit_model_confirmation_dialog_state, :atom, default: :closed
  data delete_benefit_model_confirmation_dialog_state, :atom, default: :closed

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_benefit_model_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_benefit_model_form", %{"benefit_model_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, benefit_model_id: id)}
  end

  @impl true
  def handle_event("open_edit_benefit_model_form", %{"benefit_model_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, benefit_model_id: id)}
  end

  @impl true
  def handle_event("open_edit_benefit_model_amount_form", %{"benefit_model_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_amount_mode, benefit_model_id: id)}
  end

  @impl true
  def handle_event("open_disable_benefit_model_form", %{"benefit_model_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :disable_mode, benefit_model_id: id)}
  end

  @impl true
  def handle_event(
        "open_enable_benefit_model_confirmation_dialog",
        %{"benefit_model_id" => id},
        socket
      ) do
    {:noreply,
     assign(socket, enable_benefit_model_confirmation_dialog_state: :open, benefit_model_id: id)}
  end

  @impl true
  def handle_event(
        "open_delete_benefit_model_confirmation_dialog",
        %{"benefit_model_id" => id},
        socket
      ) do
    {:noreply,
     assign(socket, delete_benefit_model_confirmation_dialog_state: :open, benefit_model_id: id)}
  end

  @impl true
  def handle_event("enable_benefit_model", _, socket) do
    %{benefit_models: benefit_models, benefit_model_id: id} = socket.assigns

    with {:ok, benefit_model} <- fetch_benefit_model(benefit_models, id),
         {:ok, benefit_model} <- HR.enable_benefit_model(benefit_model) do
      HR.broadcast_updated_benefit_model(benefit_model)
      flash_info("Valor alterado")

      {:noreply, assign(socket, closed_state())}
    else
      error -> handle_error(error, socket)
    end
  end

  @impl true
  def handle_event("delete_benefit_model", _, socket) do
    %{benefit_models: benefit_models, benefit_model_id: id} = socket.assigns

    with {:ok, benefit_model} <- fetch_benefit_model(benefit_models, id),
         {:ok, benefit_model} <- HR.delete_benefit_model(benefit_model) do
      HR.broadcast_deleted_benefit_model(benefit_model)
      flash_info("Modelo de benefício removido")

      {:noreply, assign(socket, closed_state())}
    else
      error -> handle_error(error, socket)
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="benefit_model_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@benefit_model_id}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@enable_benefit_model_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="enable_benefit_model"
        dialog_title="Confirmar Reativação do Modelo de Holerite"
        confirmation_msg="Deseja reativar o modelo de benefício?"
        action_btn_msg="Ativar"
        error_message={@message}
      />

      <ConfirmationDialog
        :if={@delete_benefit_model_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_benefit_model"
        dialog_title="Confirmar Remoção do Modelo de Holerite"
        confirmation_msg="Deseja realmente remover o modelo de benefício? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Modelos de Benefícios de Funcionários
                </span>

                <ButtonPlus on_click="open_new_benefit_model_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@benefit_models != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th class="py-3 px-3 text-left">Valor</th>
            <th class="py-3 text-left" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for benefit_model <- @benefit_models}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                <span
                  :on-click="open_show_benefit_model_form"
                  phx-value-benefit_model_id={benefit_model.id}
                  class="cursor-pointer hover:underline"
                >
                  {benefit_model.description}
                </span>

                <span :if={!is_nil(benefit_model.disabled_at)} class="label-gray ml-1">
                  inativo
                </span>
              </td>

              <td class="py-3 px-3 text-left">
                {capitalize_type(benefit_model.type)}
              </td>

              <td class="py-3 px-3 text-left">
                {benefit_model.amount}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_benefit_model_form"
                    phx-value-benefit_model_id={benefit_model.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_edit_benefit_model_amount_form"
                    phx-value-benefit_model_id={benefit_model.id}
                    class="dropdown-item"
                  >
                    Atualizar Valor
                  </a>

                  {#if !is_nil(benefit_model.disabled_at)}
                    <a
                      :on-click="open_enable_benefit_model_confirmation_dialog"
                      phx-value-benefit_model_id={benefit_model.id}
                      class="dropdown-item"
                    >
                      Ativar
                    </a>
                  {#else}
                    <a
                      :on-click="open_disable_benefit_model_form"
                      phx-value-benefit_model_id={benefit_model.id}
                      class="dropdown-item"
                    >
                      Desativar
                    </a>
                  {/if}

                  <a
                    :on-click="open_delete_benefit_model_confirmation_dialog"
                    phx-value-benefit_model_id={benefit_model.id}
                    class="dropdown-item"
                  >
                    Remover
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
      message: nil,
      benefit_model_id: nil,
      form_state: :closed,
      edit_amount_form_state: :closed,
      disable_amount_form_state: :closed,
      enable_benefit_model_confirmation_dialog_state: :closed,
      delete_benefit_model_confirmation_dialog_state: :closed
    ]
  end

  defp fetch_benefit_model(benefit_models, benefit_model_id) do
    case Enum.find(benefit_models, &(&1.id == benefit_model_id)) do
      nil -> {:error, "Modelo não encontrado"}
      benefit_model -> {:ok, benefit_model}
    end
  end

  defp handle_error({:error, message}, socket) when is_binary(message) do
    {:noreply, assign(socket, message: message)}
  end

  defp handle_error({:error, changeset}, socket) when is_struct(changeset) do
    {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
  end
end
