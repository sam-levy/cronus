defmodule SigLive.EmployeeRegistrations.Payslips do
  use SigLive, :surface_live_component

  alias SigLive.EmployeeRegistrations.Payslips.List
  alias SigLive.EmployeeRegistrations.Payslips.Show
  alias SigLive.EmployeeRegistrations.Payslips.Payables

  prop registration, :struct, required: true
  prop entity, :struct, required: true
  prop payslips, :list, required: true
  prop select_payslip, :event, required: true
  prop selected_payslip, :struct, default: nil
  prop selected_payslip_items, :list, default: []
  prop selected_payslip_payables, :list, default: []
  prop payslip_id, :string, default: nil
  prop payment_difference, :struct, default: Money.new(0)

  @impl true
  def update(
        %{selected_payslip: _, selected_payslip_items: _, selected_payslip_payables: _} = assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_payment_difference()}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="flex mt-7 divide-x divide-gray-400 divide-opacity-50">
      <div class="w-3/4 pr-5">
        <Show
          id="payslip_show"
          payslip={@selected_payslip}
          items={@selected_payslip_items}
          {=@registration}
        />

        <Payables.List
          id="payables_list"
          payslip={@selected_payslip}
          payables={@selected_payslip_payables}
          {=@payment_difference}
          {=@registration}
          {=@entity}
        />
      </div>

      <div class="w-1/4 pl-5">
        <List
          id="payslip_list"
          selected_payslip_id={@selected_payslip && @selected_payslip.id}
          {=@select_payslip}
          {=@registration}
          {=@payslips}
        />
      </div>
    </div>
    """
  end

  defp assign_payment_difference(%{assigns: %{selected_payslip: nil}} = socket), do: socket

  defp assign_payment_difference(socket) do
    %{
      assigns: %{
        selected_payslip: payslip,
        selected_payslip_items: items,
        selected_payslip_payables: payables
      }
    } = socket

    payables_amount_sum = Enum.reduce(payables, Money.new(0), &Money.add(&2, &1.amount))

    payment_in_advance_items_sum =
      Enum.reduce(items, Money.new(0), fn
        %{is_payment_advance: true, amount: amount}, acc -> Money.add(amount, acc)
        _, acc -> acc
      end)

    total_to_pay = Money.add(payslip.amount, payment_in_advance_items_sum)

    assign(socket, payment_difference: Money.subtract(total_to_pay, payables_amount_sum))
  end
end
