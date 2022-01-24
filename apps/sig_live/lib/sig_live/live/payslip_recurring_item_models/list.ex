defmodule SigLive.PayslipRecurringItemModels.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.PayslipRecurringItemModels.Form

  prop org, :struct, required: true
  prop payslip_recurring_item_models, :list, required: true

  data payslip_recurring_item_model_id, :string, default: nil
  data form_state, :atom, default: :closed
  data delete_item_model_confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_item_model_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event(
        "open_show_item_model_form",
        %{"payslip_recurring_item_model_id" => id},
        socket
      ) do
    {:noreply, assign(socket, form_state: :show_mode, payslip_recurring_item_model_id: id)}
  end

  @impl true
  def handle_event(
        "open_edit_item_model_form",
        %{"payslip_recurring_item_model_id" => id},
        socket
      ) do
    {:noreply, assign(socket, form_state: :edit_mode, payslip_recurring_item_model_id: id)}
  end

  @impl true
  def handle_event(
        "open_delete_item_model_confirmation_dialog",
        %{"payslip_recurring_item_model_id" => id},
        socket
      ) do
    {:noreply,
     assign(socket,
       delete_item_model_confirmation_dialog_state: :open,
       payslip_recurring_item_model_id: id
     )}
  end

  @impl true
  def handle_event("delete_item_model", _, socket) do
    %{
      payslip_recurring_item_models: payslip_recurring_item_models,
      payslip_recurring_item_model_id: payslip_recurring_item_model_id
    } = socket.assigns

    with {:ok, item_model} <-
           fetch_item_model(payslip_recurring_item_models, payslip_recurring_item_model_id),
         {:ok, item_model} <- HR.delete_payslip_recurring_item_model(item_model) do
      HR.broadcast_deleted_payslip_recurring_item_model(item_model)
      flash_info("Modelo de item removido")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_item_model(payslip_recurring_item_models, payslip_recurring_item_model_id) do
    case Enum.find(payslip_recurring_item_models, &(&1.id == payslip_recurring_item_model_id)) do
      nil -> {:error, "Modelo de item não encontrado"}
      item_model -> {:ok, item_model}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="item_model_create_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip_recurring_item_model_id}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@delete_item_model_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_item_model"
        dialog_title="Confirmar Remoção do Modelo de Item Recorrente"
        confirmation_msg="Deseja realmente remover o modelo de item recorrente? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Modelos de Itens de Holerite
                </span>

                <ButtonPlus on_click="open_new_item_model_form" />
              </div>
            </th>
          </tr>

          <tr class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Nome</th>
            <th class="py-3 px-3 text-left">Código</th>
            <th class="py-3 px-3 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Valor</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th class="py-3 text-left" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for item_model <- @payslip_recurring_item_models}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                <span
                  :on-click="open_show_item_model_form"
                  phx-value-payslip_recurring_item_model_id={item_model.id}
                  class="cursor-pointer hover:underline"
                >
                  {item_model.description}
                </span>
              </td>

              <td class="px-3 text-left">
                {format_type(item_model.category.code)}
              </td>

              <td class="px-3 text-left">
                {format_type(item_model.category.description)}
              </td>

              <td class="px-3 text-left">
                {#if item_model.is_fixed_amount}
                  Fixo: {item_model.amount}
                {#else}
                  Variável
                {/if}
              </td>

              <td class="px-3 text-left">
                <span class={handle_label_class(item_model.category.entry_type)}>
                  {format_type(item_model.category.entry_type)}
                </span>
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_item_model_form"
                    phx-value-payslip_recurring_item_model_id={item_model.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_item_model_confirmation_dialog"
                    phx-value-payslip_recurring_item_model_id={item_model.id}
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

  defp handle_label_class(:credit), do: "label-blue"
  defp handle_label_class(:debit), do: "label-red"

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      message: nil,
      payslip_recurring_item_model_id: nil,
      form_state: :closed,
      delete_item_model_confirmation_dialog_state: :closed
    ]
  end
end
