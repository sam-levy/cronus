defmodule SigLive.BankAccounts.List do
  use SigLive, :surface_live_component

  alias SigLive.BankAccounts.Form
  alias SigLive.Components.DropdownOpts

  prop accounts, :list, required: true
  prop entity, :struct, required: true

  data form_state, :atom, default: :closed
  data account_id, :struct, default: nil

  @impl true
  def handle_event("open_new_form", _, socket) do
    {:noreply, assign(socket, form_state: :new_mode, account_id: nil)}
  end

  @impl true
  def handle_event("open_edit_form", %{"account-id" => id}, socket) do
  	{:noreply, assign(socket, form_state: :edit_mode, account_id: id)}
  end

  @impl true
  def handle_event("open_show_form", %{"account-id" => id}, socket) do
  	{:noreply, assign(socket, form_state: :show_mode, account_id: id)}
  end

  @impl true
  def handle_event("close_form", _, socket) do
    {:noreply, assign(socket, form_state: :closed, account_id: nil)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form
        :if={@form_state != :closed}
        id="bank_account_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        form_state={@form_state}
        entity={@entity}
        account_id={@account_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="sticky top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">Contas Bancárias</span>

                <button :on-click="open_new_form" class="btn-blue">
                  <svg class="group-hover:text-light-blue-600 text-light-blue-500 mr-2" width="12" height="20" fill="currentColor">
                    <path fill-rule="evenodd" clip-rule="evenodd" d="M6 5a1 1 0 011 1v3h3a1 1 0 110 2H7v3a1 1 0 11-2 0v-3H2a1 1 0 110-2h3V6a1 1 0 011-1z"/>
                  </svg>

                  Adicionar
                </button>
              </div>
            </th>
          </tr>

          <tr :if={@accounts != []} class="bg-gray-50 uppercase text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-6 text-left">Banco</th>
            <th></th>
            <th class="py-3 px-6 text-left">Chave PIX</th>
            <th class="py-3 px-6 text-left">Agência</th>
            <th class="py-3 px-6 text-left">Conta</th>
            <th></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for account <- @accounts}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td class="py-3 pl-6 text-left cursor-pointer hover:underline" :on-click="open_show_form" phx-value-account_id={account.id}>
                {bank_name_with_number(account.routing_number)}
              </td>

              <td class="px-3 text-left">
                <div class="flex items-center">
                  <span :if={!account.is_active} class="label-red mr-1">Inativa</span>
                  <span :if={account.is_primary} class="label-green">Principal</span>
                </div>
              </td>

              <td class="px-3 text-left">
                {account.pix_key}
              </td>

              <td class="px-3 text-left">
                {account.branch_number}
              </td>

              <td class="px-3 text-left">
                {account.number}
              </td>

              <td class="pr-6 text-left">
                <DropdownOpts>
                  <a :on-click="open_edit_form" phx-value-account_id={account.id} class="dropdown-opts-item" >Editar</a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id) do
    send_update(__MODULE__, id: id, form_state: :closed, account_id: nil)
  end
end
