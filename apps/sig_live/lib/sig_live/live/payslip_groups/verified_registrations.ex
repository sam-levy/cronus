defmodule SigLive.PayslipGroups.VerifiedRegistrations do
  use SigLive, :surface_component

  prop registrations, :list, required: true

  @impl true
  def render(assigns) do
    ~F"""
    <div class="mt-3 p-3 bg-gray-100 rounded-md">
      <table class="w-full">
        <tbody>
          {#for %{individual: individual, registered_at: company, last_sector: sector} <- @registrations}
            <tr class="text-xs font-medium text-gray-500 tracking-wider odd:bg-gray-200">
              <td class="py-1 px-2 text-left">{individual.name}</td>
              <td class="py-1 px-2 text-left">{sector.name}</td>
              <td class="py-1 px-2 text-right">{company.trade_name}</td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end
end
