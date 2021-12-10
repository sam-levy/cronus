defmodule SigLive.PayslipTemplates.PayslipTemplateItems.List do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.PayslipTemplates.PayslipTemplateItems.Form

  prop payslip_template_items, :list, required: true
  prop payslip_template, :struct, required: true
  prop org, :struct, required: true

  data payslip_template_item_id, :string, default: nil
  data form_state, :atom, default: :closed
  data confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_payslip_template_item_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event(
        "open_delete_confirmation_dialog",
        %{"payslip_template_item_payslip_recurring_item_model_id" => id},
        socket
      ) do
    {:noreply,
     assign(socket,
       confirmation_dialog_state: :open,
       payslip_template_item_payslip_recurring_item_model_id: id
     )}
  end

  @impl true
  def handle_event("delete_payslip_template_item", _, socket) do
    %{
      payslip_template_items: payslip_template_items,
      payslip_template_item_payslip_recurring_item_model_id:
        payslip_template_item_payslip_recurring_item_model_id
    } = socket.assigns

    with {:ok, payslip_template_item} <-
           fetch_payslip_template_item(
             payslip_template_items,
             payslip_template_item_payslip_recurring_item_model_id
           ),
         {:ok, payslip_template_item} <- HR.delete_payslip_template_item(payslip_template_item) do
      HR.broadcast_deleted_payslip_template_item(payslip_template_item)
      send(self(), {:flash, :info, "Item removido"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_payslip_template_item(
         payslip_template_items,
         payslip_template_item_payslip_recurring_item_model_id
       ) do
    case Enum.find(
           payslip_template_items,
           &(&1.payslip_recurring_item_model_id ==
               payslip_template_item_payslip_recurring_item_model_id)
         ) do
      nil -> {:error, "Item não encontrado"}
      payslip_template_item -> {:ok, payslip_template_item}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="payslip_template_item_create_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip_template}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payslip_template_item"
        dialog_title="Confirmar Remoção do Item do Modelo de Holerite"
        confirmation_msg="Deseja realmente remover o item do modelo de holerite? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  {@payslip_template.name}

                  <span class="text-gray-300 italic">
                    Modelo de Holerite
                  </span>
                </span>

                <ButtonPlus on_click="open_new_payslip_template_item_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@payslip_template_items != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-3 text-left">Código</th>
            <th class="py-3 px-3 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Valor</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th class="py-3 px-3 text-left"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for %{payslip_recurring_item_model: item_model} = payslip_template_item <- @payslip_template_items}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
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
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-payslip_template_item_payslip_recurring_item_model_id={payslip_template_item.payslip_recurring_item_model_id}
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
      payslip_template_item_id: nil,
      form_state: :closed,
      confirmation_dialog_state: :closed
    ]
  end
end
