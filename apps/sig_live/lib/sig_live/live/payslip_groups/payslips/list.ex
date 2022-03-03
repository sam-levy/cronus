defmodule SigLive.PayslipGroups.Payslips.List do
  use SigLive, :surface_live_component

  alias SigLive.Components.Icon

  prop payslips, :list, required: true
  prop selected_payslip_id, :string

  prop companies, :list
  prop payslips_filters, :map, default: %{company_entity_id: "", individual_entity_name: ""}

  prop select_payslip, :event, required: true
  prop filter_payslips, :event

  @impl true
  def render(assigns) do
    ~F"""
    <div class="w-full flex flex-col items-end space-y-4">
      <div class="w-full bg-white shadow-md py-2 px-2 text-sm rounded-md border-2 border-white">
        <form :on-change={@filter_payslips} :on-keyup={@filter_payslips} class="space-y-3">
          <select :if={@companies} name="company_entity_id" class="form-input text-gray-500">
            <option value="" selected={is_nil(@payslips_filters.company_entity_id)}>
              Todas as Empresas
            </option>

            {#for company <- @companies}
              <option
                value={company.entity_id}
                selected={company.entity_id == @payslips_filters.company_entity_id}
              >
                {company.trade_name}
              </option>
            {/for}
          </select>

          <input
            class="form-input text-gray-500"
            type="search"
            name="individual_entity_name"
            placeholder="Nome do Funcionário"
            value={@payslips_filters.individual_entity_name}
            autocomplete="off"
          />
        </form>
      </div>

      <div class="w-full space-y-3">
        {#for payslip <- @payslips}
          <div
            :on-click={@select_payslip}
            phx-value-payslip_id={payslip.id}
            class={selectable_card_classes(payslip.id, @selected_payslip_id)}
          >
            <div class="text-gray-500">
              <div>{payslip.registration.individual.name}</div>

              <div class="text-gray-400 font-light">
                {payslip.registration.registered_at.trade_name}
              </div>
            </div>

            <Icon name="lock_open" :if={!payslip.is_closed} size="4" class="ml-2" />
          </div>
        {#else}
          <div class="text-gray-400 text-center tracking-wider">Não há holerites</div>
        {/for}
      </div>
    </div>
    """
  end

  defp selectable_card_classes(id, id), do: ~w(border-blue-500) ++ base_card_classes()
  defp selectable_card_classes(_id, _selected_id), do: ~w(border-white) ++ base_card_classes()

  defp base_card_classes do
    ~w(flex justify-between items-center bg-white shadow-md py-2 px-3 text-sm rounded-md border-2 cursor-pointer select-none)
  end
end
