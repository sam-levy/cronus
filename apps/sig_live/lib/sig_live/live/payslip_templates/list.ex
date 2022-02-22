defmodule SigLive.PayslipTemplates.List do
  use SigLive, :surface_live_component

  alias Surface.Components.LiveRedirect

  alias Sig.HR

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.PayslipTemplates.Form

  prop org, :struct, required: true
  prop payslip_templates, :list, required: true

  data payslip_template_id, :string, default: nil
  data form_state, :atom, default: :closed
  data confirmation_dialog_state, :atom, default: :closed
  data message, :string, default: nil

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_new_payslip_template_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode)}
  end

  @impl true
  def handle_event("open_show_payslip_template_form", %{"payslip_template_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, payslip_template_id: id)}
  end

  @impl true
  def handle_event("open_edit_payslip_template_form", %{"payslip_template_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, payslip_template_id: id)}
  end

  @impl true
  def handle_event("open_copy_payslip_template_form", %{"payslip_template_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :copy_mode, payslip_template_id: id)}
  end

  @impl true
  def handle_event(
        "open_delete_payslip_template_confirmation_dialog",
        %{"payslip_template_id" => id},
        socket
      ) do
    {:noreply, assign(socket, confirmation_dialog_state: :open, payslip_template_id: id)}
  end

  @impl true
  def handle_event("delete_payslip_template", _, socket) do
    %{payslip_templates: payslip_templates, payslip_template_id: payslip_template_id} =
      socket.assigns

    with {:ok, payslip_template} <-
           fetch_payslip_template(payslip_templates, payslip_template_id),
         {:ok, payslip_template} <- HR.delete_payslip_template(payslip_template) do
      HR.broadcast_deleted_payslip_template(payslip_template)
      flash_info("Modelo de holerite removido")

      {:noreply, assign(socket, closed_state())}
    else
      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}

      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, message: Sig.Changeset.errors_to_string(changeset))}
    end
  end

  defp fetch_payslip_template(payslip_templates, payslip_template_id) do
    case Enum.find(payslip_templates, &(&1.id == payslip_template_id)) do
      nil -> {:error, "Modelo não encontrado"}
      payslip_template -> {:ok, payslip_template}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="payslip_template_create_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@payslip_template_id}
        {=@form_state}
        {=@org}
      />

      <ConfirmationDialog
        :if={@confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payslip_template"
        dialog_title="Confirmar Remoção do Modelo de Holerite"
        confirmation_msg="Deseja realmente remover o modelo de holerite? Esta ação não poderá ser desfeita."
        action_btn_msg="Remover"
        error_message={@message}
      />

      <table class="w-full bg-white shadow-lg">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Modelos de Holerite
                </span>

                <ButtonPlus on_click="open_new_payslip_template_form" />
              </div>
            </th>
          </tr>

          <tr
            :if={@payslip_templates != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Nome</th>
            <th class="py-3 text-left" />
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for payslip_template <- @payslip_templates}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left">
                <LiveRedirect
                  to={Routes.sig_payslip_templates_show_path(@socket, :payslip_templates, @org, payslip_template)}
                  class="hover:underline"
                >
                  {payslip_template.name}
                </LiveRedirect>
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :on-click="open_copy_payslip_template_form"
                    phx-value-payslip_template_id={payslip_template.id}
                    class="dropdown-item"
                  >
                    Copiar
                  </a>

                  <a
                    :on-click="open_edit_payslip_template_form"
                    phx-value-payslip_template_id={payslip_template.id}
                    class="dropdown-item"
                  >
                    Renomear
                  </a>

                  <a
                    :on-click="open_delete_payslip_template_confirmation_dialog"
                    phx-value-payslip_template_id={payslip_template.id}
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
      payslip_template_id: nil,
      form_state: :closed,
      confirmation_dialog_state: :closed
    ]
  end
end
