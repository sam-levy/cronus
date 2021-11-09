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
          :if={@selected_payslip_items != []}
          id="payables_list"
          payslip={@selected_payslip}
          payables={@selected_payslip_payables}
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
end
