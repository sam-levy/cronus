defmodule SigLive.BankAccounts.List do
  use SigLive, :surface_live_component

  alias SigLive.BankAccounts.AccountForm
  alias SigLive.BankAccounts.AssociationForm
  alias SigLive.Components.DropdownBtn
  alias SigLive.Components.DropdownOpts

  prop org, :struct, required: true
  prop entity, :struct, required: true
  prop bank_accounts, :list, required: true
  prop entity_bank_accounts, :list, required: true

  data account_form_state, :atom, default: :closed, values!: AccountForm.states()
  data association_form_state, :atom, default: :closed, values!: AssociationForm.states()
  data account_id, :string, default: nil

  @impl true
  def handle_event("open_new_account_form", _, socket) do
    {:noreply, assign(socket, account_form_state: :new_mode, account_id: nil)}
  end

  @impl true
  def handle_event("open_edit_account_form", %{"account_id" => id}, socket) do
    {:noreply, assign(socket, account_form_state: :edit_mode, account_id: id)}
  end

  @impl true
  def handle_event("open_show_account_form", %{"account_id" => id}, socket) do
    {:noreply, assign(socket, account_form_state: :show_mode, account_id: id)}
  end

  @impl true
  def handle_event("open_new_association_form", _, socket) do
    {:noreply, assign(socket, association_form_state: :new_mode, account_id: nil)}
  end

  @impl true
  def handle_event("open_edit_association_form", %{"account_id" => id}, socket) do
    {:noreply, assign(socket, association_form_state: :edit_mode, account_id: id)}
  end

  @impl true
  def handle_event("open_show_association_form", %{"account_id" => id}, socket) do
    {:noreply, assign(socket, association_form_state: :show_mode, account_id: id)}
  end

  @impl true
  def handle_event("close_form", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <AccountForm
        :if={@account_form_state != :closed}
        id="account_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        form_state={@account_form_state}
        {=@entity}
        {=@account_id}
      />

      <AssociationForm
        :if={@association_form_state != :closed}
        id="association_form"
        close_event="close_form"
        close_fun={fn -> close_form(@id) end}
        form_state={@association_form_state}
        {=@org}
        {=@entity}
        {=@account_id}
      />

      <table class="w-full bg-white shadow-lg my-7">
        <thead class="top-0 z-20">
          <tr class="bg-white">
            <th colspan="6">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">Contas Bancárias</span>

                <DropdownBtn>
                  <a :on-click="open_new_account_form" class="dropdown-item">Conta Bancária</a>
                  <a :on-click="open_new_association_form" class="dropdown-item">Associação Entre Contas</a>
                </DropdownBtn>
              </div>
            </th>
          </tr>

          <tr
            :if={@bank_accounts != [] || @entity_bank_accounts != []}
            class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
          >
            <th class="py-3 px-6 text-left">Banco</th>
            <th></th>
            <th class="py-3 px-3 text-left">Chave PIX</th>
            <th class="py-3 px-3 text-left">Agência</th>
            <th class="py-3 px-3 text-left">Conta</th>
            <th></th>
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for account <- @bank_accounts}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                :on-click="open_show_account_form"
                phx-value-account_id={account.id}
                class="py-3 pl-6 text-left cursor-pointer hover:underline"
              >
                {bank_name_with_number(account.routing_number)}
              </td>

              <td class="px-3 text-left">
                <div class="flex items-center">
                  <span :if={!account.is_active} class="label-red mr-1">Inativa</span>
                  <span :if={account.is_primary} class="label-green">Principal</span>
                </div>
              </td>

              <td class="px-3 text-left select-all">
                {account.pix_key}
              </td>

              <td class="px-3 text-left">
                {account.branch_number}
              </td>

              <td class="px-3 text-left">
                {account.number}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a :on-click="open_edit_account_form" phx-value-account_id={account.id} class="dropdown-item">Editar Conta</a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}

          {#for %{bank_account: account} = eba <- @entity_bank_accounts}
            <tr class="border-b border-gray-200 hover:bg-gray-50">
              <td
                :on-click="open_show_association_form"
                phx-value-account_id={account.id}
                class="py-3 pl-6 text-left cursor-pointer hover:underline truncate"
              >
                {bank_name_with_number(account.routing_number)}
              </td>

              <td class="px-3 text-left">
                <div class="flex items-center">
                  <span class="label-gray mr-1">Associada</span>
                  <span :if={eba.is_primary} class="label-green">Principal</span>
                </div>
              </td>

              <td class="px-3 text-left select-all">
                {account.pix_key}
              </td>

              <td class="px-3 text-left">
                {account.branch_number}
              </td>

              <td class="px-3 text-left">
                {account.number}
              </td>

              <td class="pr-5 text-right">
                <DropdownOpts>
                  <a :on-click="open_edit_association_form" phx-value-account_id={account.id} class="dropdown-item">Editar Associação</a>
                </DropdownOpts>
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state do
    [account_form_state: :closed, association_form_state: :closed, account_id: nil]
  end

  defp closed_state(id), do: closed_state() ++ [id: id]
end
