defmodule SigLive.EmployeeRegistrations.Payslips.Payables.List do
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias SigLive.Components.ButtonPlus
  alias SigLive.Components.ConfirmationDialog
  alias SigLive.Components.DropdownOpts
  alias SigLive.EmployeeRegistrations.Payslips.Payables.Form

  prop org, :struct, required: true
  prop current_user, :struct, required: true
  prop registration, :struct, required: true
  prop payslip, :struct, required: true
  prop entity, :struct, required: true
  prop payslip_payables, :list, default: []
  prop payment_difference, :struct, default: Money.new(0)

  data delete_confirmation_dialog_state, :atom, default: :closed, values!: ConfirmationDialog.states()
  data form_state, :atom, default: :closed, values!: Form.states()
  data payable_id, :string, default: nil
  data message, :string, default: nil

  @impl true
  def handle_event("open_new_payable_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode, payable_id: nil)}
  end

  @impl true
  def handle_event("open_show_payable_form", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :show_mode, payable_id: id)}
  end

  @impl true
  def handle_event("open_edit_payable_form", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, form_state: :edit_mode, payable_id: id)}
  end

  @impl true
  def handle_event("open_delete_confirmation_dialog", %{"payable_id" => id}, socket) do
    {:noreply, assign(socket, delete_confirmation_dialog_state: :open, payable_id: id)}
  end

  @impl true
  def handle_event("set_as_auto_adjustable_amount", %{"payable_id" => id}, socket) do
    %{payslip: payslip} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         {:ok, _payable} <- Finance.set_payable_for_payslip_as_auto_adjustable(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)

      {:noreply, socket}
    else
      {:error, message} ->
        send(self(), {:flash, :error, message})

        {:noreply, assign(socket, closed_state())}
    end
  end

  @impl true
  def handle_event("unset_as_auto_adjustable_amount", %{"payable_id" => id}, socket) do
    %{payslip: payslip} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         {:ok, _payable} <- Finance.unset_payable_for_payslip_as_auto_adjustable(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)

      {:noreply, socket}
    else
      {:error, message} ->
        send(self(), {:flash, :error, message})

        {:noreply, assign(socket, closed_state())}
    end
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("delete_payable", _, socket) do
    %{payslip: payslip, payable_id: payable_id} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, payable_id),
         {:ok, _payable} <- Finance.delete_payable_for_payslip(payslip, payable) do
      Finance.broadcast_payables_for_payslip(payslip)
      send(self(), {:flash, :info, "Pagamento removido"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, changeset} when is_struct(changeset) ->
        message = Sig.Changeset.errors_to_string(changeset)

        {:noreply, assign(socket, message: message)}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def handle_event("authorize_payable", %{"payable_id" => id}, socket) do
    %{payslip: payslip, current_user: current_user} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         {:ok, _payable} <- Finance.authorize_payable_for_payslip(payslip, payable, current_user) do
      Finance.broadcast_payables_for_payslip(payslip)
      send(self(), {:flash, :info, "Pagamento autorizado"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, changeset} ->
        send(self(), {:flash, :error, Sig.Changeset.errors_to_string(changeset)})

        {:noreply, assign(socket, closed_state())}
    end
  end

  @impl true
  def handle_event("unauthorize_payable", %{"payable_id" => id}, socket) do
    %{payslip: payslip} = socket.assigns

    with {:ok, payable} <- Finance.fetch_payable_by_payslip(payslip, id),
         {:ok, _payable} <- Finance.unauthorize_payable_for_payslip(payable) do
      Finance.broadcast_payables_for_payslip(payslip)
      send(self(), {:flash, :info, "Pagamento desautorizado"})

      {:noreply, assign(socket, closed_state())}
    else
      {:error, changeset} ->
        send(self(), {:flash, :error, Sig.Changeset.errors_to_string(changeset)})

        {:noreply, assign(socket, closed_state())}
    end
  end

  @impl true
  def render(%{payslip: nil} = assigns) do
    ~F"""
    <div></div>
    """
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <ConfirmationDialog
        :if={@delete_confirmation_dialog_state != :closed}
        close_event="close_modals"
        action_event="delete_payable"
        dialog_title="Confirmar Remoção"
        confirmation_msg="Deseja realmente remover o pagamento?"
        action_btn_msg="Remover"
        error_message={@message}
      />

      <Form
        :if={@form_state != :closed}
        id="payable_form"
        close_event="close_modals"
        close_fun={fn -> close_modals(@id) end}
        {=@form_state}
        {=@org}
        {=@entity}
        {=@registration}
        {=@payslip}
        {=@payable_id}
      />

      <table class="w-full bg-white shadow-lg mb-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="5">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider mr-4">
                  Pagamentos
                </span>

                <ButtonPlus on_click="open_new_payable_form"/>
              </div>
            </th>
          </tr>

          <tr
            :if={@payslip_payables != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Vencimento</th>
            <th class="py-3 px-6 text-left">Descrição</th>
            <th class="py-3 px-6 text-right">Valor</th>
            <th class="py-3 px-6 text-right"></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for payable <- @payslip_payables}
            <tr class="border-b hover:bg-gray-50">
              <td class="py-3 px-6 text-left">
                <a
                  :on-click="open_show_payable_form"
                  phx-value-payable_id={payable.id}
                  class="cursor-pointer hover:underline"
                >
                  {format_date(payable.due_date)}
                </a>
              </td>

              <td class="py-3 px-6 text-left">
                <div class="flex items-center">
                  {payable.description}

                  <span :if={payable.authorized_by_id} class="label-green ml-3">autorizado</span>
                </div>
              </td>

              <td class="py-3 px-6">
                <div class="flex justify-end items-center">
                  <span
                    :if={!payable.financial_transaction_id and payable.payslip_payable.is_auto_adjustable_amount}
                    class="label-gray mr-3"
                  >
                    automático
                  </span>

                  {format_amount(payable.amount)}
                </div>
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a
                    :if={!payable.authorized_by_id}
                    :on-click="authorize_payable"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Autorizar pagamento
                  </a>

                  <a
                    :if={payable.authorized_by_id}
                    :on-click="unauthorize_payable"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Desautorizar pagamento
                  </a>

                  <a
                    :if={
                      !payable.financial_transaction_id and
                      !payable.authorized_by_id and
                      !payable.payslip_payable.is_auto_adjustable_amount
                    }
                    :on-click="set_as_auto_adjustable_amount"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Atribuir valor automático
                  </a>

                  <a
                    :if={!payable.financial_transaction_id and payable.payslip_payable.is_auto_adjustable_amount}
                    :on-click="unset_as_auto_adjustable_amount"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Remover valor automático
                  </a>

                  <a
                    :if={!payable.financial_transaction_id and !payable.authorized_by_id}
                    :on-click="open_edit_payable_form"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Editar
                  </a>

                  <a
                    :if={!payable.financial_transaction_id and !payable.authorized_by_id}
                    :on-click="open_delete_confirmation_dialog"
                    phx-value-payable_id={payable.id}
                    class="dropdown-item"
                  >
                    Remover
                  </a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          <tr
            :if={@payment_difference != Money.new(0)}
            class="text-sm bg-gray-100 font-medium text-gray-500 tracking-wider"
          >
            <td class="py-2 px-6 text-left" colspan="2">Diferença</td>
            <td class="py-2 px-6 text-right">{format_amount(@payment_difference)}</td>
            <td></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      payable_id: nil,
      message: nil,
      form_state: :closed,
      delete_confirmation_dialog_state: :closed
    ]
  end
end
