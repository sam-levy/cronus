  defmodule SigLive.EmployeeRegistrations.RecurringPayslipItems.MonthToggle do
    use SigLive, :surface_component

    prop target, :date, required: true
    prop floor, :date
    prop cap, :date
    prop previous, :event
    prop next, :event

    @impl true
    def render(assigns) do
      ~F"""
      <div class="flex items-center text-gray-500 font-medium text-sm tracking-wider rounded-md">
        <button :on-click={@previous} {...props_for(:previous, @target, @floor)}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M15.707 15.707a1 1 0 01-1.414 0l-5-5a1 1 0 010-1.414l5-5a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 010 1.414zm-6 0a1 1 0 01-1.414 0l-5-5a1 1 0 010-1.414l5-5a1 1 0 011.414 1.414L5.414 10l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd" />
          </svg>
        </button>

        <div class="inline-block w-32">{format_month(@target)}</div>

        <button :on-click={@next} {...props_for(:next, @target, @cap)}>
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10.293 15.707a1 1 0 010-1.414L14.586 10l-4.293-4.293a1 1 0 111.414-1.414l5 5a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0z" clip-rule="evenodd" />
            <path fill-rule="evenodd" d="M4.293 15.707a1 1 0 010-1.414L8.586 10 4.293 5.707a1 1 0 011.414-1.414l5 5a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
      """
    end

    @base_btn_class "select-none rounded-md py-1 px-2 "

    @btn_enabled [disabled: false, class: @base_btn_class <> "hover:bg-gray-100"]
    @btn_disabled [disabled: true, class: @base_btn_class <> "text-gray-300 cursor-default"]

    defp props_for(:previous, _target, nil), do: @btn_enabled

    defp props_for(:previous, target, floor) do
      case Date.compare(target, floor) do
        :gt -> @btn_enabled
        _ -> @btn_disabled
      end
    end

    defp props_for(:next, _target, nil), do: @btn_enabled

    defp props_for(:next, target, cap) do
      case Date.compare(target, cap) do
        :lt -> @btn_enabled
        _ -> @btn_disabled
      end
    end
  end
