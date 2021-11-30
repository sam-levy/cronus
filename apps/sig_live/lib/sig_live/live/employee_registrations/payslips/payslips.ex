defmodule SigLive.EmployeeRegistrations.Payslips do
  use SigLive, :surface_live_component

  alias SigLive.EmployeeRegistrations.Payslips.List
  alias SigLive.Payslips.ShowWithPayables

  prop current_user, :struct, required: true
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
  def render(assigns) do
    ~F"""
    <div class="flex divide-x divide-gray-400 divide-opacity-50">
      <div class="w-3/4 pr-5">
        <ShowWithPayables
          id="payslip_show_with_payables"
          payslip={@selected_payslip}
          payslip_items={@selected_payslip_items}
          payslip_payables={@selected_payslip_payables}
          {=@registration}
          {=@current_user}
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
end
