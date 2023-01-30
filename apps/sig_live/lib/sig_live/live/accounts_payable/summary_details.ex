defmodule SigLive.AccountsPayable.SummaryDetails do
  @moduledoc """
  This module is temporary and should be removed as soon as the bank account
  management feature is fully implemented.
  """
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias SigLive.Components.Modal

  prop org, :struct, required: true
  prop close_event, :event, required: true
  prop selected_payable_ids, :string, required: true

  @impl true
  def update(assigns, socket) do
    %{org: org, selected_payable_ids: ids} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payables: Finance.list_payables_by(org, payable_ids: ids, preload: [:payslip, :employee])
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Pagamentos" close={@close_event}>
      <div class="space-y-6 divide-y divide-gray-300">
        <ul role="list" class="bg-gray-50 rounded-lg divide-y divide-gray-200">
          {#for payable <- @payables}
            <a
              class="py-3 px-4 block hover:bg-gray-100 hover:rounded-lg"
              href={Routes.sig_employee_registrations_show_path(
                @socket,
                :payslip,
                @org,
                payable.payslip.registration_id,
                payable.payslip
              )}
              target="_blank"
            >
              <div class="flex items-center space-x-4">
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900">
                    {#case payable}
                      {#match %{employee: %Ecto.Association.NotLoaded{}}}
                        {payable.description}
                      {#match _}
                        {payable.description} {payable.employee.name}
                    {/case}
                  </p>

                  <p class="text-sm text-gray-500">
                    {format_date(payable.due_date)}
                  </p>
                </div>

                <div class="inline-flex items-center text-base font-semibold text-gray-900">
                  {format_amount(payable.amount)}
                </div>
              </div>
            </a>
          {/for}
        </ul>
      </div>
    </Modal>
    """
  end

  defp transaction_type(%{entry_type: :debit}), do: "Débito"
  defp transaction_type(_), do: "Crédito"
end
