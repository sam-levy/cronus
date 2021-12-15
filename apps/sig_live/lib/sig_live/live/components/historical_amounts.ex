defmodule SigLive.Components.HistoricalAmounts do
  use SigLive, :surface_component

  prop historical_amounts, :list, default: []

  @impl true
  def render(assigns) do
    ~F"""
      <div class="mt-5 p-3 bg-gray-100 rounded-md">
        <div class="form-label">Histórico de Valores</div>

        <table class="w-full mt-3">
          <tbody class="">
            {#for historical_amount <- @historical_amounts}
              <tr class="text-xs font-medium text-gray-500 tracking-wider odd:bg-gray-200">
                <td class="py-1 px-2 rounded-md text-left">{format_date(historical_amount.date)}</td>
                <td class="py-1 px-2 rounded-md text-right">{format_amount(historical_amount.amount)}</td>
              </tr>
            {/for}
          </tbody>
        </table>
      </div>
    """
  end
end
