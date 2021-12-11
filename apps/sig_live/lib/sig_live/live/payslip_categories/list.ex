defmodule SigLive.PayslipCategories.List do
  use SigLive, :surface_live_component

  alias Surface.Components.LiveRedirect

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.PayslipCategories.Form

  prop org, :struct, required: true
  prop payslip_categories, :list, required: true

  data payslip_category_id, :string, default: nil
  data form_state, :atom, default: :closed
  data confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_payslip_category_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_edit_payslip_category_form", %{"payslip_category_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, payslip_category_id: id)}
  end

  @impl true
  def handle_event("open_delete_payslip_category_confirmation_dialog", %{"payslip_category_id" => id}, socket) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, payslip_category_id: id)}
  end

  @impl true
  def handle_event("delete_payslip_category", _, socket) do
    %{payslip_categories: payslip_categories, payslip_category_id: payslip_category_id} = socket.assigns

    with {:ok, payslip_category} <- fetch_payslip_category(payslip_categories, payslip_category_id),
         {:ok, payslip_category} <- HR.delete_payslip_category(payslip_category) do
      HR.broadcast_deleted_payslip_category(payslip_category)
      send(self(), {:flash, :info, "Categoria removida"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_payslip_category(payslip_categories, payslip_category_id) do
    case Enum.find(payslip_categories, & &1.id == payslip_category_id) do
      nil -> {:error, "Categoria não encontrada"}
      payslip_category -> {:ok, payslip_category}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="payslip_category_create_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip_category_id}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payslip_category"
        dialog_title="Confirmar Remoção da Categoria"
        confirmation_msg="Deseja realmente remover a categoria? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Categorias de Itens de Holerite
                </span>

                <ButtonPlus on_click="open_new_payslip_category_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@payslip_categories != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-3 text-left">Código</th>
            <th class="py-3 px-3 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Tipo</th>
            <th class="py-3 px-3 text-left"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for category <- @payslip_categories}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                {format_type(category.code)}
              </td>

              <td class="px-3 text-left">
                {format_type(category.description)}
              </td>

              <td class="px-3 text-left">
                <span class={handle_label_class(category.entry_type)}>
                  {format_type(category.entry_type)}
                </span>

                <span :if={category.is_payment_advance} class="label-gray ml-1">
                  adiantamento
                </span>
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_edit_payslip_category_form"
                    phx-value-payslip_category_id={category.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :on-click="open_delete_payslip_category_confirmation_dialog"
                    phx-value-payslip_category_id={category.id}
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
      payslip_category_id: nil,
      form_state: :closed,
      confirmation_dialog_state: :closed
    ]
  end
end
