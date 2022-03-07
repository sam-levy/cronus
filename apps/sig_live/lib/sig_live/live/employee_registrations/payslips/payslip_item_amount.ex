defmodule SigLive.EmployeeRegistrations.Payslips.PayslipItemAmount do
  use SigLive, :surface_component

  prop item, :struct, required: true
  prop edit_event, :event, required: true
  prop is_editable, :boolean, required: false

  def render(assigns) do
    ~F"""
    {#if @is_editable}
      <a
        :on-click={@edit_event}
        phx-value-item_id={@item.id}
        class="p-1.5 rounded hover:bg-gray-200 border border-transparent hover:border-gray-400 cursor-text"
      >
        {@item.amount}
      </a>
    {#else}
      <span class="p-1.5 border border-transparent">
        {@item.amount}
      </span>
    {/if}
    """
  end
end
