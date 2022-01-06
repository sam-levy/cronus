defmodule SigLive.AccountsPayable.PayFooter do
  use SigLive, :surface_live_component

  prop message, :string, default: nil
  prop selected_payables, :map, required: true
  prop selected_amount_sum, :struct, required: true
  prop clear, :event, required: true

  @impl true
  def update(assigns, socket) do
    %{selected_payables: selected_payables} = assigns

    selected_payables_count = Enum.count(selected_payables)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        selected_payables_count: selected_payables_count,
        transaction_description: build_description(selected_payables, selected_payables_count)
       )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="flex absolute bottom-0 left-0 right-0 bg-white shadow-2xl p-3 h-32">
      <div class="w-full max-w-5xl px-4 mx-auto text-gray-600 text-md ">
        <div class="flex justify-between">
          <div class="">
            <div>Valor: {format_amount(@selected_amount_sum)}</div>

            {#if @selected_payables_count > 1}
              <div class="text-gray-500 text-sm font-light italic">{@selected_payables_count} pagáveis selecionados</div>
            {/if}

            {@message}
          </div>

          <div class="">
            {@transaction_description}
          </div>
        </div>
      </div>

      <div>
        <div
          :on-click={@clear}
          class="ml-2 p-1 hover:bg-gray-100 hover:rounded-md cursor-pointer text-gray-500"
        >
          <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
      </div>
    </div>
    """
  end

  defp build_description(payables, 1) do
    [payable] = Map.values(payables)

    build_description(payable)
  end

  defp build_description(_payables, _count), do: ""

  defp build_description(%{target: :payslip} = payable) do
    "#{payable.description} #{payable.employee.name}"
  end

  defp build_description(_payable), do: ""
end
