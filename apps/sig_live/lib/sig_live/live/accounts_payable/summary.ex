defmodule SigLive.AccountsPayable.Summary do
  @moduledoc """
  This module is temporary and should be removed as soon as the bank account
  management feature is fully implemented.
  """

  use SigLive, :surface_live_component

  alias Sig.Finance.FinancialTransactions.Summary
  alias Sig.Entities

  alias SigLive.AccountsPayable.SummaryDetails

  prop org, :struct, required: true
  prop org_bank_accounts, :list, required: true
  prop financial_transactions, :list, required: true
  prop financial_transaction_ids, :mapset, required: true

  data description, :string, default: "Vale Funcionários"
  data details_modal_open, :boolean, default: false
  prop selected_financial_transaction_ids, :list, default: []

  @impl true
  def update(assigns, socket) do
    %{
      org: org,
      org_bank_accounts: org_bank_accounts,
      financial_transactions: financial_transactions,
      financial_transaction_ids: financial_transaction_ids
    } = assigns

    {:ok,
     assign(socket,
       org: org,
       org_bank_accounts: build_accounts_to_display(org_bank_accounts),
       clearing_dates: list_clearing_dates(financial_transactions),
       companies: Entities.list_companies(org),
       summary: Summary.build(org, financial_transaction_ids)
     )}
  end

  defp build_accounts_to_display(accounts) do
    indexed_accounts = Map.new(accounts, &{&1.name, &1})

    Enum.map(Summary.accounts_to_display(), &Map.get(indexed_accounts, &1))
  end

  defp list_clearing_dates(transactions) do
    Enum.reduce(transactions, MapSet.new(), fn
      %{clearing_date: nil}, acc -> acc
      %{clearing_date: date}, acc -> MapSet.put(acc, date)
    end)
  end

  @impl true
  def handle_event("close_modals", _, socket) do
    {:noreply, assign(socket, closed_state())}
  end

  @impl true
  def handle_event("open_details_modal", %{"selected_financial_transaction_ids" => ids}, socket) do
    {:noreply,
     assign(socket, selected_financial_transaction_ids: String.split(ids), details_modal_open: true)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <SummaryDetails
        :if={@details_modal_open}
        id="summary_details_modal"
        close_event="close_modals"
        {=@selected_financial_transaction_ids}
        {=@org}
      />

      <table class="w-full bg-white shadow-lg my-5">
        <thead>
          <tr class="bg-white">
            <th colspan="2">
              <div class="flex justify-between items-center py-3 px-6">
                <span class="text-gray-500 font-medium tracking-wider">
                  Fluxo
                </span>
              </div>
            </th>
          </tr>

          <tr :if={@summary != %{}} class="bg-gray-100 text-xs font-medium text-gray-500 tracking-wider">
            <th class="py-3 px-3 text-center">Data</th>
            <th class="py-3 px-3 text-left">Descrição</th>
            <th class="py-3 px-3 text-left">Titular</th>
            <th></th>

            {#for %{name: name} <- @org_bank_accounts}
              <th class="py-3 px-3 text-right">{name}</th>
            {/for}
          </tr>
        </thead>

        <tbody class="text-gray-600 text-sm font-light">
          {#for clearing_date <- @clearing_dates, %{trade_name: company_trade_name} <- @companies}
            <tr class=" border-b border-gray-200 hover:bg-gray-50">
              <td class="py-1 px-3 text-center">{format_date(clearing_date)}</td>
              <td class="px-3 text-left">{@description}</td>
              <td class="px-3 text-left">{translate(company_trade_name)}</td>
              <td></td>

              {#for %{name: bank_name} <- @org_bank_accounts}
                <td class="px-3 text-right text-red-600 hover:bg-gray-200">
                  <a
                    class="cursor-pointer hover:underline"
                    :on-click="open_details_modal"
                    phx-value-selected_financial_transaction_ids={handle_selected_financial_transaction_ids(@summary, clearing_date, bank_name, company_trade_name)}
                  >
                    {handle_amount_sum(@summary, clearing_date, bank_name, company_trade_name)}
                  </a>
                </td>
              {/for}
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end

  defp handle_selected_financial_transaction_ids(summary, clearing_date, bank_name, company_trade_name) do
    case Map.get(summary, {clearing_date, bank_name, company_trade_name}) do
      %{financial_transaction_ids: ids} -> Enum.join(ids, " ")
      nil -> nil
    end
  end

  defp handle_amount_sum(summary, clearing_date, bank_name, company_trade_name) do
    case Map.get(summary, {clearing_date, bank_name, company_trade_name}) do
      %{amount_sum: amount_sum} -> Money.multiply(amount_sum, -1)
      nil -> ""
    end
  end

  def close_modals(id), do: send_update(__MODULE__, closed_state(id))

  defp closed_state(id), do: closed_state() ++ [id: id]

  defp closed_state do
    [
      selected_financial_transaction_ids: nil,
      details_modal_open: false
    ]
  end

  defp translate("Call Center"), do: "call center"
  defp translate("Central de Processamento"), do: "central"
  defp translate("Escritório"), do: "escritorio"
  defp translate("CiB Mogi"), do: "mogi"
  defp translate("CiB Penha"), do: "penha"
  defp translate("CiB São Miguel"), do: "smiguel"
  defp translate("CiB Suzano"), do: "suzano"
  defp translate(_), do: "NÃO LISTADO"
end
