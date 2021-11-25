defmodule SigLive.Payslips.ShowWithPayables do
  use SigLive, :surface_live_component

  alias SigLive.EmployeeRegistrations.Payslips.Show
  alias SigLive.EmployeeRegistrations.Payslips.Payables

  prop current_user, :struct, required: true
  prop registration, :struct, required: true
  prop entity, :struct, required: true
  prop payslip, :struct, default: nil
  prop payslip_items, :list, default: []
  prop payslip_payables, :list, default: []
  prop payslip_id, :string, default: nil

  data payment_difference, :struct, default: Money.new(0)

  @impl true
  def update(
        %{payslip: _, payslip_items: _, payslip_payables: _} = assigns,
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
    <div>
      <Show
        id="payslip_show"
        items={@payslip_items}
        {=@payslip}
        {=@registration}
      />

      <Payables.List
        id="payables_list"
        {=@payslip_payables}
        {=@payslip}
        {=@payment_difference}
        {=@current_user}
        {=@registration}
        {=@entity}
      />
    </div>
    """
  end

  defp assign_payment_difference(%{assigns: %{payslip: nil}} = socket), do: socket

  defp assign_payment_difference(socket) do
    %{
      assigns: %{
        payslip: payslip,
        payslip_items: items,
        payslip_payables: payables
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
